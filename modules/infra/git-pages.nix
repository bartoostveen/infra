{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkDefault
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
      default = { };
    };
  };
  config = mkIf cfg.enable {
    services.git-pages.settings = {
      audit = {
        collect = mkDefault false;
        include-ip = mkDefault "";
        node-id = mkDefault 0;
        notify-url = mkDefault "";
      };
      fallback = {
        insecure = mkDefault false;
        proxy-to = mkDefault "https://codeberg.page";
      };
      limits = {
        allow-basic-auth = mkDefault false;
        allow-expiration = mkDefault false;
        allowed-custom-headers = mkDefault [ "X-Clacks-Overhead" ];
        allowed-repository-url-prefixes = mkDefault [ ];
        concurrent-uploads = mkDefault 1024;
        forbidden-domains = mkDefault [ ];
        git-large-object-threshold = mkDefault "1M";
        max-heap-size-ratio = mkDefault 0.5;
        max-inline-file-size = mkDefault "256B";
        max-manifest-size = mkDefault "1M";
        max-site-size = mkDefault "128M";
        max-symlink-depth = mkDefault 16;
        update-timeout = mkDefault "60s";
      };
      log-format = mkDefault "text";
      observability.slow-response-threshold = mkDefault "500ms";
      server = {
        caddy = mkDefault "-";
        metrics = mkDefault "-";
        pages = mkDefault "tcp/localhost:3000";
      };
      storage.fs.root = mkDefault "./data";
    };

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
