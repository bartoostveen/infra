{
  config,
  inputs,
  lib,
  pkgs,
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
    getExe
    ;

  inherit (types) bool listOf str;

  cfg = config.mailserver;
  metaCfg = config.infra.mail;

  rspamdMetricsPort = 32475;
  tlsaExporterPort = 19309;
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
    autoconfig = mkOption {
      description = "Whether to enable autoconfig";
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
    tlsa = mkOption {
      description = "Whether TLSA is enabled";
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

  config = mkIf (metaCfg.enableDefaults) {
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

    # In order to support consistent DANE TLSA
    security.acme.certs."${cfg.systemDomain}".extraLegoRenewFlags = mkIf metaCfg.tlsa [
      "--reuse-key"
    ];

    services.rspamd.workers.controller.bindSockets = [ "*:${toString rspamdMetricsPort}" ];
    services.prometheus.exporters = {
      dovecot.enable = true;
      postfix.enable = true;
    };
    infra.extraScrapeConfigs.rspamd.port = rspamdMetricsPort;

    sops.secrets = mkIf (metaCfg.sops) (
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
          metaCfg.additionalDeniedRecipients
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

    # ----------- DANE/TLSA EXPORTER ----------- #
    infra.extraScrapeConfigs.tlsa = mkIf metaCfg.tlsa { port = tlsaExporterPort; };
    systemd.services.prometheus-tlsa-exporter = mkIf metaCfg.tlsa {
      description = "Prometheus TLSA exporter";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        MTCE_SERVER_PORT = toString tlsaExporterPort;
        MTCE_TLSA_RECORD = "_25._tcp.${cfg.fqdn}";
        MTCE_SMTP_HOSTNAME = cfg.fqdn;
        MTCE_SMTP_PORT = "587";
        MTCE_SMTP_CLIENT = "tlsa-smtp-synthetics-probe";
        MTCE_CHECK_TIMEOUT = "15000";
        MTCE_IPV4_ENABLED = "true";
        MTCE_IPV6_ENABLED = "true";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${getExe pkgs.nodejs_24} ${inputs.tlsa-exporter}/index.mjs
        '';
        Restart = "always"; # because it is intended for the server to crash for some reason
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MountAPIVFS = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = "strict";
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = 27;
      };
    };
    # ----------- DANE/TLSA EXPORTER ----------- #

    services.nginx.virtualHosts."autoconfig.${cfg.systemDomain}" = mkIf metaCfg.autoconfig {
      enableACME = true;
      forceSSL = true;
      locations."= /mail/config-v1.1.xml".root = pkgs.writeTextDir "mail/config-v1.1.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>

        <clientConfig version="1.1">
         <emailProvider id="${cfg.systemDomain}">
           <domain>${cfg.systemDomain}</domain>
           <displayName>${cfg.systemName}</displayName>
           <displayShortName>${cfg.systemDomain}</displayShortName>
           <incomingServer type="imap">
             <hostname>${cfg.fqdn}</hostname>
             <port>993</port>
             <socketType>SSL</socketType>
             <authentication>password-cleartext</authentication>
             <username>%EMAILADDRESS%</username>
           </incomingServer>
           <outgoingServer type="smtp">
             <hostname>${cfg.fqdn}</hostname>
             <port>465</port>
             <socketType>SSL</socketType>
             <authentication>password-cleartext</authentication>
             <username>%EMAILADDRESS%</username>
           </outgoingServer>
         </emailProvider>
        </clientConfig>
      '';
    };
  };
}
