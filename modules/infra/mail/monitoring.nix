{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkIf getExe;

  cfg = config.mailserver;
  metaCfg = config.infra.mail;

  rspamdMetricsPort = 32475;
  tlsaExporterPort = 19309;
in
{
  services.rspamd.workers.controller.bindSockets = [ "*:${toString rspamdMetricsPort}" ];
  services.prometheus.exporters = {
    dovecot.enable = true;
    postfix.enable = true;
  };
  infra.extraScrapeConfigs.rspamd.port = rspamdMetricsPort;

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
}
