{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    getExe
    optional
    ;

  inherit (types)
    bool
    nullOr
    str
    submodule
    attrsOf
    package
    port
    path
    ;

  cfg = config.services.maubot-exporter;
in
{
  options.services.maubot-exporter = {
    enable = mkEnableOption "maubot-exporter";
    package = mkOption {
      description = "maubot-exporter package";
      type = package;
      default = pkgs.local.maubot-exporter;
    };
    local = mkOption {
      description = "whether to depend on the local maubot instance";
      type = bool;
      default = true;
      example = false;
    };
    listen = mkOption {
      description = "Listen address";
      type = str;
      default = "0.0.0.0";
      example = "127.0.0.1";
    };
    port = mkOption {
      description = "Port";
      type = port;
      default = 9100;
      example = 12345;
    };
    settings = mkOption {
      description = "Settings (env vars) for maubot-exporter";
      type = submodule {
        freeformType = attrsOf str;
        options = {
          MAUBOT_API_BASE = mkOption {
            description = "The value of the MAUBOT_API_BASE env var, the maubot base url WITHOUT the trailing slash";
            type = str;
            example = "https://maubot.example.com/_matrix/maubot/v1";
          };
          MAUBOT_USERNAME = mkOption {
            description = "The value of the MAUBOT_USERNAME env var, the username of a maubot user";
            type = nullOr str;
            example = "admin";
          };
          MAUBOT_PASSWORD = mkOption {
            description = "The value of the MAUBOT_PASSWORD env var, the password of the maubot user, do not use in production!";
            type = nullOr str;
            default = null;
            example = "changeme";
          };
        };
      };
      default = { };
      example = {
        MAUBOT_API_BASE = "https://maubot.example.com/_matrix/maubot/v1";
        MAUBOT_USERNAME = "admin";
        MAUBOT_PASSWORD = "changeme";
      };
    };
    environmentFile = mkOption {
      description = "path to the environment file containing variables such as the auth password";
      type = nullOr path;
      default = null;
      example = "/run/path/to/secret/environment/file.env";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.maubot-exporter = {
      description = "maubot-exporter - Simple metrics exporter for maubot";
      after = optional cfg.local "maubot.service";
      requires = optional cfg.local "maubot.service";
      wantedBy = [ "multi-user.target" ];
      environment = cfg.settings;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${getExe cfg.package} --bind ${cfg.listen}:${toString cfg.port}";
        EnvironmentFile = cfg.environmentFile;
        DynamicUser = true;
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
  };
}
