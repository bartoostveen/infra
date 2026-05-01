{
  config,
  inputs,
  lib,
  ...
}:

let
  inherit (lib)
    mkDefault
    genAttrs
    mkForce
    mkOption
    types
    mkIf
    genAttrs'
    attrNames
    nameValuePair
    concatStringsSep
    ;

  inherit (types) bool listOf str;

  cfg = config.mailserver;

  rspamdMetricsPort = 32475;
in
{
  imports = [
    inputs.nixos-mailserver.nixosModule
  ];

  options.infra.mail = {
    enableDefaults = mkOption {
      description = "Whether to enable global email defaults";
      type = bool;
      default = true;
      example = false;
    };
    sops = mkOption {
      description = "Whether to automatically import DKIM sops secrets from secrets/dkim";
      type = bool;
      default = true;
      example = false;
    };
    additionalDeniedRecipients = mkOption {
      description = "list of additionally denied full addresses";
      type = listOf str;
      default = [ ];
    };
  };

  config = mkIf (config.infra.mail.enableDefaults) {
    mailserver = {
      enable = mkDefault true;
      fqdn = mkDefault "mx.${cfg.systemDomain}";
      x509.useACMEHost = mkDefault cfg.systemDomain;
      domains = mkDefault [ cfg.systemDomain ];

      dmarcReporting.enable = true;
      tlsrpt.enable = true;
      systemContact = mkDefault "postmaster@${cfg.systemDomain}";

      enableManageSieve = true;
      enableSubmission = true; # Enable StartTLS

      hierarchySeparator = "/"; # See: https://doc.dovecot.org/main/core/config/namespaces.html#namespaces

      fullTextSearch = {
        enable = true;
        autoIndex = true;
      };

      dkim.domains = genAttrs cfg.domains (name: {
        selectors.mail.keyFile = config.sops.secrets."${name}.mail.key".path;
      });

      useUTF8FolderNames = mkForce true;

      stateVersion = mkDefault 4; # Only change this line after performing state migrations!
    };

    services.nginx.virtualHosts."${cfg.systemDomain}" = {
      serverAliases = (lib.lists.remove cfg.systemDomain cfg.domains) ++ [ cfg.fqdn ];
      forceSSL = mkDefault true;
      enableACME = mkForce true;
    };

    services.rspamd.workers.controller.bindSockets = [ "*:${toString rspamdMetricsPort}" ];
    services.prometheus.exporters = {
      dovecot.enable = true;
      postfix.enable = true;
    };
    infra.extraScrapeConfigs.rspamd.port = rspamdMetricsPort;

    sops.secrets = mkIf (config.infra.mail.sops) (
      genAttrs' (attrNames cfg.dkim.domains) (
        name:
        nameValuePair "${name}.mail.key" {
          format = "binary";
          owner = "rspamd";
          group = "rspamd";
          mode = "0600";
          sopsFile = ../../secrets/dkim/${name}.mail.private.secret;
          restartUnits = [ "rspamd.service" ];
        }
      )
    );

    services.postfix =
      let
        deniedRecipientsFileName = "denied_recipients_additional";
      in
      {
        mapFiles.${deniedRecipientsFileName} = builtins.toFile deniedRecipientsFileName (
          config.infra.mail.additionalDeniedRecipients
          |> map (n: "${n} REJECT This account cannot receive emails.")
          |> concatStringsSep "\n"
        );

        settings.main = {
          inet_protocols = mkForce "ipv4, ipv6";
          bounce_template_file = mkDefault "${./bounce-template.cf}";
          smtpd_recipient_restrictions = [
            "check_recipient_access hash:/var/lib/postfix/conf/${deniedRecipientsFileName}"
          ];
        };
      };

    infra.backup.jobs.state.paths = [ config.mailserver.storage.path ];
  };
}
