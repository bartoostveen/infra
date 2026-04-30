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

  inherit (lib) concatStringsSep mkForce;

  domain = "popkoorklankkleur.nl";

  ldapBase = "dc=ldap,dc=popkoorklankkleur,dc=nl";
  ldapPasswordFile = config.sops.secrets.ldap-bind-password.path;
  ldapHost = "${domain}:3389";
  ldapBindDN = "cn=ldapservice,ou=users,${ldapBase}";
  ldapGroupsFile = "/run/postfix/ldap-groups.cf";
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

  rspamdMetricsPort = 32475;
in
{
  imports = [
    inputs.nixos-mailserver.nixosModule
  ];

  mailserver = {
    enable = true;

    fqdn = "mx.${domain}";
    systemDomain = domain;
    x509.useACMEHost = domain;
    domains = [ domain ];

    # DKIM/DMARC
    dmarcReporting.enable = true;
    tlsrpt.enable = true;
    systemContact = "postmaster@${domain}";

    hierarchySeparator = "/"; # See: https://doc.dovecot.org/main/core/config/namespaces.html#namespaces

    enableManageSieve = true;
    enableImap = true;
    enableSubmission = true; # Enable StartTLS

    dkim.domains.${domain}.selectors.mail.keyFile =
      config.sops.secrets."popkoorklankkleur.nl.mail.key".path;

    ldap =
      let
        uidAttribute = "sAMAccountName";
      in
      {
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

    useUTF8FolderNames = true;

    stateVersion = 4; # Do not change this line, unless a new version needs to be migrated to
  };

  services.nginx.virtualHosts.${domain}.serverAliases = [ config.mailserver.fqdn ];

  services.postfix =
    let
      deniedRecipientsFileName = "denied_recipients_additional";
    in
    {
      mapFiles.${deniedRecipientsFileName} = builtins.toFile deniedRecipientsFileName (
        [
          "onboarding"
          "cloud"
        ]
        |> map (n: "${n}@${domain} REJECT This account cannot receive emails.")
        |> concatStringsSep "\n"
      );

      settings.main = {
        inet_protocols = "ipv4, ipv6";
        bounce_template_file = "${./bounce-template.cf}";
        virtual_alias_maps = [ "ldap:${ldapGroupsFile}" ];

        smtpd_recipient_restrictions = [
          "check_recipient_access hash:/var/lib/postfix/conf/${deniedRecipientsFileName}"
        ];
      };
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

  services.rspamd.workers.controller.bindSockets = [ "*:${toString rspamdMetricsPort}" ];

  infra.extraScrapeConfigs.rspamd = {
    port = rspamdMetricsPort;
    metrics_path = "/metrics";
  };

  services.roundcube = {
    enable = true;
    package =
      let
        oidcPlugin = pkgs.local.roundcube-oidc.override {
          configText = ''
            <?php

            $config['oidc_imap_master_password'] = trim(file_get_contents("${dovecotMasterPasswordFile}"));
            $config['oidc_master_user_separator'] = '${dovecotSeparator}';
            $config['oidc_config_master_user'] = '${dovecotMasterUser}';
            $config['oidc_url'] = 'https://auth.popkoorklankkleur.nl/application/o/webmail/';
            $config['oidc_client'] = 'VZITfwq9s64f2JJp6Rdb7EGPWnYrQqRU0S1ZrUw5';
            $config['oidc_secret'] = trim(file_get_contents("${roundcubeClientSecretFile}"));
            $config['oidc_scope'] = 'openid profile roundcube';
            $config['oidc_field_uid'] = 'webmail_email';
          '';
        };
        roundcubeWithPlugins = pkgs.roundcube.withPlugins (_: [ oidcPlugin ]);
      in
      roundcubeWithPlugins;
    hostName = "webmail.${domain}";
    plugins = [
      "roundcube_oidc"
      "managesieve"
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

      $config['ldap_public']['public'] = array(
          'name'              => 'Alle addressen',
          'hosts'             => array('ldap://${ldapHost}'),
          'writable'          => false,
          'ldap_version'      => 3,
          'user_specific'     => false,
          'base_dn'           => 'ou=users,${ldapBase}',
          'bind_dn'           => '${ldapBindDN}',
          'bind_pass'         => file_get_contents("${ldapPasswordFile}"),
          'filter'            => '(objectClass=inetOrgPerson)'
      );
    '';
  };

  services.phpfpm.pools.roundcube.settings."php_admin_value[open_basedir]" =
    "/run/secrets:/nix/store:/tmp";

  sops.secrets."popkoorklankkleur.nl.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../../../secrets/dkim/popkoorklankkleur.nl.mail.key.secret;

    restartUnits = [ "rspamd.service" ];
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

  infra.backup.jobs.state.paths = [ config.mailserver.storage.path ];
}
