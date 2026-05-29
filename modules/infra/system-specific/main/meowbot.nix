{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) getExe;
in
{
  systemd.services.meowbot = {
    description = "meow :3";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = getExe inputs.meowbot.packages.${pkgs.stdenv.system}.default;
      EnvironmentFile = config.sops.secrets.meowbot-env.path;
      Restart = "on-failure";
      DynamicUsers = true;
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
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = 27;
      StateDirectory = "meowbot";
      StateDirectoryMode = "750";
      WorkingDirectory = "%S/meowbot";
    };
  };

  infra.backup.jobs.state.paths = [ "/var/lib/meowbot" ];

  sops.secrets.meowbot-env = {
    format = "binary";
    sopsFile = ../../../../secrets/meowbot.env.bart-server.secret;
    restartUnits = [ "meowbot.service" ];
  };
}
