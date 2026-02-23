{
  pkgs,
  lib,
  config,
  ...
}:

let
  metrics-port = 61152;
  fail2ban-socket = config.services.fail2ban.daemonSettings.Definition.socket;

  inherit (lib) getExe;
in
{
  services.fail2ban = {
    enable = true;
    daemonSettings.Definition.socket = "/run/fail2ban/fail2ban.sock";
    ignoreIP = [ "100.64.0.0/10" ];
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "fail2ban";
      static_configs = [
        {
          targets = [ "127.0.0.1:${toString metrics-port}" ];
        }
      ];
    }
  ];

  systemd.services.prometheus-fail2ban-exporter = {
    description = "Prometheus fail2ban exporter";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${getExe pkgs.local.fail2ban-prometheus-exporter} \
          --collector.f2b.socket=${fail2ban-socket} \
          --web.listen-address="127.0.0.1:${toString metrics-port}" \
          --collector.f2b.exit-on-socket-connection-error
      '';
      Restart = "on-failure";
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
