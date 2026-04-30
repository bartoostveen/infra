{
  config,
  lib,
  inputs,
  ...
}:

let
  domain = "bartoostveen.nl";
  rspamdMetricsPort = 32475;

  dkimDomains = [
    "bartoostveen.nl"
    "boostveen.nl"
    "omeduostuurcentenneef.nl"
    "vitune.app"
  ];

  inherit (lib) genAttrs genAttrs' nameValuePair;
in
{
  imports = [
    inputs.nixos-mailserver.nixosModule

    ./passwords.nix
    ./accounts.nix
  ];

  # TODO: generalize
  mailserver = {
    enable = true;

    fqdn = "mx.${domain}";
    systemDomain = domain;
    x509.useACMEHost = domain;

    domains = [
      domain
      "vitune.app"
      "omeduostuurcentenneef.nl"
    ];

    dkim.domains = genAttrs dkimDomains (name: {
      selectors.mail.keyFile = config.sops.secrets."${name}.mail.key".path;
    });

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
    };

    useUTF8FolderNames = true;

    stateVersion = 4; # Do not change this line, unless a new version needs to be migrated to
  };

  services.rspamd.workers.controller.bindSockets = [ "*:${toString rspamdMetricsPort}" ];
  services.prometheus.exporters = {
    dovecot.enable = true;
    postfix.enable = true;
  };
  infra.extraScrapeConfigs.rspamd.port = rspamdMetricsPort;

  services.nginx.virtualHosts."${config.mailserver.systemDomain}" = {
    serverName = config.mailserver.systemDomain;
    serverAliases = lib.lists.remove config.mailserver.systemDomain config.mailserver.domains;
    forceSSL = true;
    enableACME = true;
  };

  sops.secrets = genAttrs' dkimDomains (
    name:
    nameValuePair "${name}.mail.key" {
      format = "binary";
      owner = "rspamd";
      group = "rspamd";
      mode = "0600";

      sopsFile = ../../../../../secrets/dkim/${name}.mail.private.secret;

      restartUnits = [ "rspamd.service" ];
    }
  );

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

  services.postfix.settings.main = {
    inet_protocols = "ipv4, ipv6";
    bounce_template_file = "${./bounce-template.cf}";
  };

  infra.backup.jobs.state.paths = [ config.mailserver.storage.path ];
}
