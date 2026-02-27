{
  config,
  lib,
  inputs,
  ...
}:

let
  domain = "bartoostveen.nl";
in
{
  imports = [
    inputs.nixos-mailserver.nixosModule

    ./passwords.nix
    ./accounts.nix
  ];

  mailserver = {
    enable = true;

    fqdn = domain;
    systemName = domain;
    systemDomain = domain;
    x509.useACMEHost = domain;

    domains = [
      domain
      "vitune.app"
      "omeduostuurcentenneef.nl"
    ];

    # DKIM/DMARC
    dmarcReporting.enable = true;
    tlsrpt.enable = true;
    systemContact = "postmaster@${domain}";

    hierarchySeparator = "/"; # See: https://doc.dovecot.org/main/core/config/namespaces.html#namespaces

    enableManageSieve = true;
    enableSubmission = true; # Enable StartTLS

    fullTextSearch = {
      enable = true;
      autoIndex = true;
      enforced = "body";
      memoryLimit = 2000; # MiB
      autoIndexExclude = [
        "Trash"
        "\\Junk"
      ];
    };

    useUTF8FolderNames = true;

    stateVersion = 3; # Do not change this line, unless a new version needs to be migrated to
  };

  services.prometheus = {
    exporters = {
      dovecot.enable = true;
      postfix.enable = true;
      rspamd.enable = true;
    };

    scrapeConfigs = [
      {
        job_name = "dovecot";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.dovecot.port}" ];
          }
        ];
      }
      {
        job_name = "postfix";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.postfix.port}" ];
          }
        ];
      }
      {
        job_name = "rspamd";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.rspamd.port}" ];
          }
        ];
      }
    ];
  };

  services.nginx.virtualHosts."${config.mailserver.fqdn}" = {
    serverName = config.mailserver.fqdn;
    serverAliases = lib.lists.remove config.mailserver.fqdn config.mailserver.domains;
    forceSSL = true;
    enableACME = true;
  };

  sops.secrets."bartoostveen.nl.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../../secrets/bartoostveen.nl.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/bartoostveen.nl.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  sops.secrets."omeduostuurcentenneef.nl.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../../secrets/omeduostuurcentenneef.nl.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/omeduostuurcentenneef.nl.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  sops.secrets."vitune.app.mail.key" = {
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0600";

    sopsFile = ../../../secrets/vitune.app.mail.private.secret;

    path = "${config.mailserver.dkimKeyDirectory}/vitune.app.mail.key";
    restartUnits = [ "rspamd.service" ];
  };

  services.roundcube = {
    enable = true;
    hostName = "webmail.bartoostveen.nl";
    extraConfig = ''
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
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
      $config['smtp_auth_type'] = 'LOGIN';
      $config['smtp_conn_options'] = array(
          'ssl' => array(
              'verify_peer'  => false,
              'verify_peer_name' => false,
          ),
      );
    '';
  };

  services.postfix = {
    submissionOptions = {
      smtpd_client_restrictions = lib.mkForce "permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination";
      smtpd_recipient_restrictions = lib.mkForce "permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination";
    };

    submissionsOptions = {
      smtpd_client_restrictions = lib.mkForce "permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination";
      smtpd_recipient_restrictions = lib.mkForce "permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination";
    };

    settings.main = {
      inet_protocols = "ipv4";
      bounce_template_file = "${./bounce-template.cf}";

      mynetworks = [
        "127.0.0.0/8"
        "46.224.181.108/32"
      ];

      smtpd_relay_restrictions = lib.mkForce [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject_unauth_destination"
      ];

      smtpd_recipient_restrictions = lib.mkForce [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject_unauth_destination"
      ];

      smtpd_client_restrictions = lib.mkForce [ "permit_mynetworks" ];
    };
  };
}
