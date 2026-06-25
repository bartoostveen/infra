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
    mkPackageOption
    types
    getExe
    ;

  inherit (types)
    submodule
    attrs
    path
    nullOr
    ;

  cfg = config.services.git-pages;

  configFormat = pkgs.formats.toml { };
in
{
  options.services.git-pages = {
    enable = mkEnableOption "git-pages, Scalable static site server for Git forges (like GitHub Pages or Netlify)";
    package = mkPackageOption pkgs "git-pages" { };
    configFile = mkOption {
      description = "file that contains the server config, overrides services.git-pages.settings!";
      type = path;
      default = configFormat.generate "git-pages.toml" cfg.settings;
      defaultText = "<<generated TOML from services.git-pages.settings>>";
    };
    environmentFile = mkOption {
      description = ''
        File that contains values for the git-pages config. This file may be used for secrets.

        ::: {.note}
        See the [git-pages documentation](https://git-pages.org/running-a-server/#environment-variables) on environment variables.
        :::
      '';
      type = nullOr path;
      default = null;
      example = "/run/secrets/git-pages.env";
    };
    settings = mkOption {
      description = "git-pages server config";
      type = submodule {
        freeformType = attrs;
        options = {
          # TODO
        };
      };
      default = {
        audit = {
          collect = false;
          include-ip = "";
          node-id = 0;
          notify-url = "";
        };
        fallback = {
          insecure = false;
          proxy-to = "https://codeberg.page";
        };
        limits = {
          allow-basic-auth = false;
          allow-expiration = false;
          allowed-custom-headers = [ "X-Clacks-Overhead" ];
          allowed-repository-url-prefixes = [ ];
          concurrent-uploads = 1024;
          forbidden-domains = [ ];
          git-large-object-threshold = "1M";
          max-heap-size-ratio = 0.5;
          max-inline-file-size = "256B";
          max-manifest-size = "1M";
          max-site-size = "128M";
          max-symlink-depth = 16;
          update-timeout = "60s";
        };
        log-format = "text";
        observability.slow-response-threshold = "500ms";
        server = {
          caddy = "-";
          metrics = "-";
          pages = "tcp/localhost:3000";
        };
        storage.fs.root = "./data";
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.services.git-pages = {
      description = "git-pages, Scalable static site server for Git forges (like GitHub Pages or Netlify)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${getExe cfg.package} -config ${cfg.configFile}
        '';
        DynamicUser = true;
        EnvironmentFile = cfg.environmentFile;
        StateDirectory = "git-pages";
        WorkingDirectory = "/var/lib/git-pages";
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
