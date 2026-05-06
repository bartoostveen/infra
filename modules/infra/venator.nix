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
    optional
    ;

  inherit (types)
    bool
    nullOr
    listOf
    int
    str
    submodule
    attrsOf
    attrs
    package
    path
    ;

  cfg = config.services.venator;

  configFormat = pkgs.formats.yaml { };
in
{
  options.services.venator = {
    enable = mkEnableOption "venator, a Matrix homeserver written from scratch in Go";
    package = mkOption {
      description = "venator package";
      type = package;
      default = pkgs.local.venator;
    };
    configurePostgres = mkEnableOption "postgres locally using services.postgresql";
    enableWrapper = mkOption {
      description = "Whether to add a wrapped venatorctl to the path that refers to the server's config file";
      type = bool;
      default = true;
      example = false;
    };
    configFile = mkOption {
      description = "file that contains the server config, overrides services.venator.settings!";
      type = path;
      default = configFormat.generate "venator.yaml" cfg.settings;
      defaultText = "<<generated YAML from services.venator.settings>>";
    };
    settings = mkOption {
      description = "venator server config";
      type = submodule {
        freeformType = attrsOf attrs;
        options = {
          database.url = mkOption {
            description = "Database URL";
            type = str;
            example = "postgresql://venator:venator@localhost:5432/venator?sslmode=disable";
          };
          listeners = mkOption {
            description = "(federation) listeners";
            type = listOf (submodule {
              options = {
                port = mkOption {
                  description = "port";
                  type = int;
                  example = 8448;
                };
                tls = mkEnableOption "tls";
              };
            });
            default = [
              {
                port = 8008;
                tls = false;
              }
              {
                port = 8448;
                tls = false;
              }
            ];
          };
          registration = {
            enabled = mkOption {
              description = "whether to enable registration";
              type = bool;
              default = true;
              example = false;
            };
            # TODO: read this from a file and warn about world-readable stuff
            admin_pre_shared_secret = mkOption {
              description = "admin PSK";
              type = nullOr str;
              default = null;
              example = "verysecretstringyes";
            };
            # TODO: read this from a file and warn about world-readable stuff
            token = mkOption {
              description = "registration token";
              type = nullOr str;
              default = null;
              example = "otherverysecretstringyes";
            };
          };
          server_name = mkOption {
            description = "Name of the server";
            type = str;
            example = "venator.localhost:8008";
          };
        };
      };
      default = {
        database = {
          max_idle_connections = 5;
          max_open_connections = 5;
        };
        logging = {
          writers = [
            {
              format = "pretty-colored";
              min_level = "debug";
              type = "stdout";
            }
          ];
        };
        media_repo.root_path = "media";
        registration.password_requirements = {
          min_entropy = 50;
          min_length = 10;
        };
      };
      example = {
        registration = {
          enabled = true;
          admin_pre_shared_secret = "foobar";
          token = "foobar";
        };
        server_name = "venator.example.com";
      };
    };
  };
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.settings.registration.enabled
          ->
            cfg.settings.registration.admin_pre_shared_secret != null
            && cfg.settings.registration.token != null;
        message = "The admin PSK and registration may both not be null if registration is enabled!";
      }
    ];

    services.venator.settings.database.url =
      mkIf cfg.configurePostgres "postgresql://venator?host=/var/run/postgresql";

    systemd.services.venator = {
      description = "Matrix Venator - versatile capital Matrix homeserver written from scratch in mautrix-go";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      requires = optional cfg.configurePostgres "postgresql.target";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${getExe cfg.package} --config ${cfg.configFile}
        '';
        DynamicUser = true;
        StateDirectory = "venator";
        WorkingDirectory = "/var/lib/venator";
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

    users.users.venator = {
      isSystemUser = true;
      group = "venator";
      description = "venator";
    };
    users.groups.venator = { };

    services.postgresql = mkIf cfg.configurePostgres {
      ensureUsers = [
        {
          name = "venator";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ "venator" ];
    };

    environment.systemPackages = mkIf cfg.enableWrapper [
      (pkgs.writeShellApplication {
        name = "venatorctl";
        runtimeInputs = [ cfg.package ];
        text = ''
          venatorctl --config ${cfg.configFile} "$@"
        '';
      })
    ];
  };
}
