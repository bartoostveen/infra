{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (import "${inputs.nixos-mailserver}/mail-server/common.nix" { inherit config pkgs lib; })
    appendLdapBindPwd
    ;

  inherit (lib) concatStringsSep mkForce splitString;

  domain = "popkoorklankkleur.nl";

  toLdapDC = domain: domain |> splitString "." |> map (part: "dc=${part}") |> concatStringsSep ",";

  ldapDomain = "ldap.${domain}";
  ldapBase = toLdapDC ldapDomain;
  ldapPasswordFile = config.sops.secrets.ldap-bind-password.path;
  ldapHost = "${ldapDomain}:3389";
  ldapBindDN = "cn=ldapservice,ou=users,${ldapBase}";
  ldapGroupsFile = "/run/postfix/ldap-groups.cf";
  uidAttribute = "sAMAccountName";
  ldapMapFile = pkgs.writeText "ldap-groups.cf" ''
    server_host = ${ldapHost}
    version = 3
    start_tls = yes

    search_base = ou=groups,${ldapBase}
    query_filter = (&(objectClass=group)(sAMAccountName=%u)(!(|(mailBindIgnore=TRUE)(mailBindIgnore=true))))
    special_result_attribute = member
    leaf_result_attribute = cn
    result_format = %s@${domain}

    bind = yes
    bind_dn = ${ldapBindDN}
  '';
  writeLdapMapFile = appendLdapBindPwd {
    name = "ldap-groups";
    file = ldapMapFile;
    prefix = "bind_pw = ";
    passwordFile = ldapPasswordFile;
    destination = ldapGroupsFile;
  };

  dovecotSeparator = "*";
  dovecotMasterUser = "master";
  dovecotMasterPasswordFile = config.sops.secrets.dovecot-master-password.path;
  dovecotMasterPasswdFile = config.sops.secrets.dovecot-master-passwd.path;
  roundcubeClientSecretFile = config.sops.secrets.roundcube-client-secret.path;

in
{
  imports = [
    ../../mail.nix
  ];

  mailserver = {
    systemDomain = domain;
    enableImap = true;

    ldap = {
      enable = true;
      uris = [ "ldap://${ldapHost}" ];
      attributes = {
        username = uidAttribute;
        uuid = "uidNumber";
      };
      dovecot = {
        userFilter = "(&(objectClass=user)(${uidAttribute}=%{user | username}))";
        passFilter = "(&(objectClass=user)(${uidAttribute}=%{user | username}))";
      };
      postfix.filter = "(&(objectClass=user)(${uidAttribute}=%u))";
      bind = {
        dn = ldapBindDN;
        passwordFile = ldapPasswordFile;
      };
      base = "ou=users,${ldapBase}";
      scope = "sub";
    };

    forwards = {
      "postmaster@${domain}" = "postmaster@bartoostveen.nl";
      "webmaster@${domain}" = "akadmin@${domain}";
    };

    stateVersion = 4;
  };

  infra.mail.additionalDeniedRecipients = [
    "onboarding@popkoorklankkleur.nl"
    "cloud@popkoorklankkleur.nl"
    "ldapservice@popkoorklankkleur.nl"
  ];

  services.postfix.settings.main = {
    bounce_template_file = "${./bounce-template.cf}";
    virtual_alias_maps = [ "ldap:${ldapGroupsFile}" ];
  };

  services.dovecot2.settings = {
    auth_master_user_separator = dovecotSeparator;
    "passdb AAAAAAAAAAAAAAAAAAAAAAAmaster" = {
      driver = "passwd-file";
      passwd_file_path = "${dovecotMasterPasswdFile}";
      result_success = "continue";
      master = "yes";
    };
    "passdb ldap" = {
      passdb_ldap_bind = "yes";
      fields.password = mkForce null;
    };
  };

  systemd.services.postfix.preStart = ''
    ${writeLdapMapFile}
  '';

  services.roundcube =
    let
      oidcPlugin = pkgs.local.roundcube-oidc.override {
        configText = ''
          <?php

          $config['oidc_imap_master_password'] = trim(file_get_contents("${dovecotMasterPasswordFile}"));
          $config['oidc_master_user_separator'] = '${dovecotSeparator}';
          $config['oidc_config_master_user'] = '${dovecotMasterUser}';
          $config['oidc_url'] = 'https://auth.popkoorklankkleur.nl/application/o/webmail/';
          $config['oidc_logout_url'] = 'https://auth.popkoorklankkleur.nl/application/o/webmail/end-session/';
          $config['oidc_client'] = 'VZITfwq9s64f2JJp6Rdb7EGPWnYrQqRU0S1ZrUw5';
          $config['oidc_secret'] = trim(file_get_contents("${roundcubeClientSecretFile}"));
          $config['oidc_scope'] = 'openid profile roundcube';
          $config['oidc_field_uid'] = 'webmail_email';
          $config['oidc_force'] = true;
        '';
      };
    in
    {
      enable = true;
      package = pkgs.roundcube.withPlugins (_: [ oidcPlugin ]);
      hostName = "webmail.${domain}";
      plugins = [
        "roundcube_oidc"
        "managesieve"
        "markasjunk"
        "newmail_notifier"
        "vcard_attachments"
        "zipdownload"
      ];
      maxAttachmentSize = 256;
      extraConfig = ''
        $config['smtp_debug'] = true;
        $config['ldap_debug'] = true;
        $config['sql_debug'] = true;
        $config['imap_debug'] = true;
        $config['debug_level'] = 1;

        $config['des_key'] = trim(file_get_contents("${config.sops.secrets.roundcube-des.path}"));

        $config['product_name'] = "Popkoor KlankKleur webmail";
        $config['skin_logo'] = "${builtins.readFile ./logo-base64.txt}";

        // always, except when replying to plain text message
        $config['htmleditor'] = 4;

        $config['username_domain'] = '${config.mailserver.systemDomain}';

        $config['imap_host'] = "ssl://${config.mailserver.fqdn}:993";
        $config['imap_auth_type'] = 'LOGIN';
        $config['imap_delimiter'] = '/';
        $config['imap_conn_options'] = array(
            'ssl' => array(
                'verify_peer'  => false,
                'verify_peer_name' => false,
            ),
        );

        $config['smtp_host'] = "ssl://${config.mailserver.fqdn}:465";
        $config['smtp_auth_type'] = 'LOGIN';
        $config['smtp_conn_options'] = array(
            'ssl' => array(
                'verify_peer'  => false,
                'verify_peer_name' => false,
            ),
        );

        $config['managesieve_host'] = "tls://${config.mailserver.fqdn}";
        $config['managesieve_port'] = 4190;
        $config['managesieve_usetls'] = true;
      '';
    };

  services.phpfpm.pools.roundcube = {
    phpOptions = ''
      opcache.enable=1
      opcache.enable_cli=1
      opcache.memory_consumption=128
      opcache.max_accelerated_files=10000
      opcache.validate_timestamps=0
    '';
    settings = {
      "php_admin_value[open_basedir]" = "/run/secrets:/nix/store:/tmp";
      "pm" = "dynamic";
      "pm.max_children" = 20;
      "pm.start_servers" = 4;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 6;
    };
  };

  sops.secrets.dovecot-master-password = {
    format = "binary";
    owner = "roundcube";
    group = "roundcube";
    sopsFile = ../../../../secrets/dovecot-master-password.secret;

    restartUnits = [
      "phpfpm-roundcube.service"
      "dovecot.service"
      "postfix.service"
    ];
  };

  sops.secrets.dovecot-master-passwd = {
    format = "binary";
    owner = "dovecot2";
    group = "dovecot2";

    sopsFile = ../../../../secrets/dovecot-master-passwd.secret;

    restartUnits = [
      "phpfpm-roundcube.service"
      "dovecot.service"
      "postfix.service"
    ];
  };

  sops.secrets.roundcube-client-secret = {
    format = "binary";
    owner = "roundcube";
    group = "roundcube";
    sopsFile = ../../../../secrets/roundcube-client.secret;

    restartUnits = [
      "phpfpm-roundcube.service"
      "dovecot.service"
      "postfix.service"
    ];
  };

  sops.secrets.roundcube-des = {
    format = "binary";
    owner = "roundcube";
    group = "roundcube";
    sopsFile = ../../../../secrets/roundcube-des.secret;

    restartUnits = [ "phpfpm-roundcube.service" ];
  };
}
