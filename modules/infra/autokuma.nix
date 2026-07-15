{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    # keep-sorted start
    attrNames
    attrValues
    attrsToList
    concatStringsSep
    filterAttrs
    filterAttrsRecursive
    flatten
    foldl'
    getExe
    groupBy
    id
    last
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mergeAttrs
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    nameValuePair
    recursiveUpdate
    removeSuffix
    types
    uniqueStrings
    # keep-sorted end
    ;

  inherit (types)
    # keep-sorted start
    attrs
    attrsOf
    bool
    enum
    int
    lines
    listOf
    nullOr
    path
    str
    submodule
    # keep-sorted end
    ;

  settingsType = submodule {
    options = {
      static_monitors = mkOption {
        description = "Directory that contains all static monitors/tags/etc., overrides declarative monitors/tags/etc.";
        default = null;
        type = nullOr path;
        example = "/etc/autokuma/monitors";
      };
      tag_name = mkOption {
        description = "The name of the AutoKuma tag, used to track managed containers";
        default = null;
        type = nullOr str;
        example = "kuma";
      };
      tag_color = mkOption {
        description = "The color of the AutoKuma tag";
        default = null;
        type = nullOr str;
        example = "#42C0FB";
      };
      default_settings = mkOption {
        description = "Default settings applied to all generated Monitors";
        default = "";
        type = lines;
        example = ''
          docker.docker_container: {{container_name}}
          http.max_redirects: 10
          *.max_retries: 3
        '';
      };
      on_delete = mkOption {
        description = "Specify what should happen to a monitor if the autokuma id is not found anymore, either `delete` or `keep`";
        default = "keep";
        type = enum [
          "delete"
          "keep"
        ];
        example = "delete";
      };
      delete_grace_period = mkOption {
        description = "How long to wait in seconds before deleting the entity if the autokuma is not not found anymore (no-op if on_delete is keep)";
        default = 60;
        type = int;
        example = 120;
      };
      insecure_env_access = mkOption {
        description = "Allow access to all env variables in templates, by default only variables starting with `AUTOKUMA__ENV__` can be accessed";
        default = false;
        type = bool;
        example = true;
      };
      snippets = mkOption {
        description = "Define snippets, see https://github.com/BigBoot/AutoKuma/tree/master?tab=readme-ov-file#snippets-";
        default = { };
        type = attrsOf lines;
        example = {
          web = ''
            {{ container_name }}_http.http.name: {{ container_name }}
            {{ container_name }}_http.http.url: https://{{ args[0] }}:{{ args[1] }}
            {{ container_name }}_docker.docker.name: {{ container_name }}_docker
            {{ container_name }}_docker.docker.docker_name: {{ container_name }}
          '';
        };
      };
      kuma = mkOption {
        description = "Settings that determine how to connect to Uptime Kuma. See https://github.com/BigBoot/AutoKuma/tree/master?tab=readme-ov-file#configuration-";
        default = { };
        type = submodule {
          options = {
            url = mkOption {
              description = "The URL AutoKuma should use to connect to Uptime Kuma";
              default = null;
              type = nullOr str;
              example = "https://uptime.example.com";
            };
            username = mkOption {
              description = "The username for logging into Uptime Kuma (required unless auth is disabled)";
              default = null;
              type = nullOr str;
              example = "adm";
            };
            password = mkOption {
              description = ''
                The password for logging into Uptime Kuma (required unless auth is disabled).

                You should ABSOLUTELY NEVER use this option in production, specify the `AUTOKUMA__KUMA__PASSWORD` environment variable instead in the envFile.
                You should manage said file using a secrets manager like sops(-nix)/agenix.
              '';
              default = null;
              type = nullOr str;
              example = "ChangeMe!";
            };
            mfa_secret = mkOption {
              description = "The MFA secret. Used to generate a tokens for logging into Uptime Kuma (alternative to a single_use mfa_token)";
              default = null;
              type = nullOr str;
              example = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
            };
            headers = mkOption {
              description = "List of HTTP headers to send when connecting to Uptime Kuma";
              default = [ ];
              type = listOf str;
              example = [
                "FOO=bar" # Yes, the '=' is not a typo, this is hardcoded at https://github.com/BigBoot/AutoKuma/blob/2fffa28564e37cb846a6aec22d58b56eca8ca25e/kuma-client/src/client.rs#L108
                "BAR=baz"
              ];
            };
            connect_timeout = mkOption {
              description = "The timeout for the initial connection to Uptime Kuma in seconds";
              default = 30;
              type = int;
              example = 60;
            };
            call_timeout = mkOption {
              description = "The timeout for executing calls to the Uptime Kuma server";
              default = 30;
              type = int;
              example = 60;
            };
          };
        };
        example = {
          url = "https://uptime.example.com";
          username = "adm";
          password = "DoNotDoThisInProdPlease";
        };
      };
      docker = mkOption {
        description = "Using Docker as an additional autokuma source is also supported using this submodule";
        default = { };
        example = {
          hosts = [ "unix:///var/run/docker.sock" ];
          label_prefix = "autokuma_";
        };
        type = submodule {
          options = {
            hosts = mkOption {
              description = "List of Docker hosts";
              default = null;
              type = nullOr (listOf str);
              example = [ "unix:///var/run/docker.sock" ];
            };
            label_prefix = mkOption {
              description = "Prefix used when scanning for container labels";
              default = "autokuma_";
              type = str;
            };
            source = mkOption {
              description = "Whether monitors should be created from `Containers` or `Services` labels (or `Both`)";
              default = "Containers";
              type = enum [
                "Containers"
                "Services"
                "Both"
              ];
              example = "Services";
            };
            exclude_container_patterns = mkOption {
              description = "Regex patterns to exclude containers by name";
              default = [ ];
              type = listOf str;
              example = [ "^[a-f0-9]{12}_.*_" ];
            };
            tls = mkOption {
              description = "Docker TLS settings";
              default = { };
              example = {
                verify = true;
                cert = "/path/to/cert.pem";
              };
              type = submodule {
                options = {
                  verify = mkOption {
                    description = "Whether to verify the TLS certificate";
                    default = false;
                    type = bool;
                    example = true;
                  };
                  cert = mkOption {
                    description = "The path to a custom tls certificate in PEM format";
                    default = null;
                    type = nullOr path;
                    example = "/path/to/cert.pem";
                  };
                };
              };
            };
            files.follow_symlinks = mkOption {
              description = "Whether AutoKuma should follow symlinks when looking for 'static monitors'";
              default = false;
              type = bool;
              example = true;
            };
          };
        };
      };
    };
  };

  cfg = config.infra.autokuma;

  trimHash =
    file:
    let
      matched = builtins.match "^[a-zA-Z0-9]\{32\}-(.+)" (baseNameOf file);
    in
    if matched == null then baseNameOf file else last matched;

  instanceKeys =
    instance:
    (
      (
        [
          instance.dockerHosts
          instance.notifications
          instance.tags
          instance.monitors
        ]
        |> map attrNames
      )
      ++ (instance.additionalMonitorFiles |> map (file: trimHash file))
    )
    |> flatten;

  allStringsUnique = list: builtins.length (uniqueStrings list) == builtins.length list;
  isDisjoint = instance: instanceKeys instance |> allStringsUnique;

  addType = type: mapAttrs (_: value: value // { inherit type; });
  mkMonitorAttrs =
    instance:
    if isDisjoint instance then
      (addType "docker_host" instance.dockerHosts)
      // (addType "notification" instance.notifications)
      // (addType "tag" instance.tags)
      // instance.monitors
    else
      throw ''
        Instance is not disjoint! Make sure the attribute names of { dockerHosts, notifications, tags, monitors }
        and the file names in additionalMonitorFiles are disjoint!

        Duplicate names:
        ${
          instance
          |> instanceKeys
          |> groupBy id
          |> filterAttrs (_: o: builtins.length o > 1)
          |> attrNames # almost the implementation of uniqueStrings (O(n)), can be seen as A - B in set notation, returns a set
          |> map (k: "- ${k}")
          |> concatStringsSep "\n"
        }
      '';

  format = pkgs.formats.toml { };

  validTOML = filterAttrsRecursive (_: v: (v != null));
in
{
  options.infra.autokuma = {
    enable = mkEnableOption "autokuma";
    package = mkPackageOption pkgs "autokuma" { };
    defaultSettings = mkOption {
      description = "Default configuration for infra.instances.*.settings.kuma";
      default = { };
      example = {
        tag_name = "AUTOKUMA";
      };
      type = settingsType;
    };
    defaultEnvFile = mkOption {
      description = "Default path to environment file for all autokuma instances, should not be a path inside the nix store, should use a secrets manager like sops(-nix)/agenix";
      default = null;
      type = nullOr path;
      example = "/run/secrets/autokuma.env";
    };
    defaultUser = mkOption {
      description = "User that autokuma runs as by default";
      default = "autokuma";
      type = str;
      example = "johndoe";
    };
    defaultGroup = mkOption {
      description = "Group that autokuma runs as by default";
      default = "autokuma";
      type = str;
      example = "johndoe";
    };
    instances = mkOption {
      description = "Instances of the autokuma daemon";
      default = { };
      example = { };
      type = attrsOf (submodule {
        options = {
          enable = mkOption {
            description = "Whether to enable this autokuma instance";
            default = true;
            type = bool;

            example = false;
          };
          user = mkOption {
            description = "User that autokuma runs as";
            default = null;
            type = nullOr str;
            example = "autokuma";
          };
          group = mkOption {
            description = "Group that autokuma runs as";
            default = null;
            type = nullOr str;
            example = "autokuma";
          };
          logLevel = mkOption {
            description = "Log level of AutoKuma";
            default = "info";
            type = enum [
              "error"
              "warn"
              "info"
              "debug"
              "trace"
            ];
            example = "debug";
          };
          additionalMonitorFiles = mkOption {
            description = "Additional monitor files to load. Can/should be used for secrets.";
            default = [ ];
            type = listOf path;
            example = [ "/run/secrets/alert-that-contains-private-access-tokens.toml" ];
          };
          settings = mkOption {
            description = "Autokuma settings";
            default = { };
            example = {
              tag_name = "AUTOKUMA";
            };
            type = settingsType;
          };
          dockerHosts = mkOption {
            description = "List of generated docker host autokumas";
            default = { };
            example = {
              docker_local = {
                connection_type = "socket";
                path = "/var/run/docker.sock";
              };
              docker_remote = {
                connection_type = "tcp";
                host = "example.com:12345";
              };
            };
            type = attrsOf (submodule {
              options = {
                connection_type = mkOption {
                  description = "Type of Docker connection";
                  type = enum [
                    "socket"
                    "tcp"
                  ];
                };
                host = mkOption {
                  description = "Remote Docker host, may not be null if path is null";
                  default = null;
                  type = nullOr str;
                  example = "example.com:12345";
                };
                path = mkOption {
                  description = "Docker socket path, may not be null if host is null";
                  default = null;
                  type = nullOr str;
                  example = "/var/run/docker.sock";
                };
              };
            });
          };
          notifications = mkOption {
            description = "List of generated autokuma notifications";
            default = { };
            example = {
              my_notification = {
                active = true;
                is_default = false;
                config = {
                  applyExisting = true;
                  disableUrl = false;
                  discordChannelType = "channel";
                  discordUsername = "Uptime Kuma";
                  discordWebhookUrl = "https://discord.com/api/webhooks/1234567890123456789/foobarbaz";
                  isDefault = true;
                  name = "Discord Hook";
                  type = "discord";
                };
              };
            };
            type = attrsOf (submodule {
              options = {
                active = mkOption {
                  description = "Whether the notification should be active";
                  default = true;
                  type = bool;
                  example = false;
                };
                is_default = mkOption {
                  description = "Whether the notification is on by default";
                  default = false;
                  type = bool;
                  example = true;
                };
                config = mkOption {
                  description = "Notification config, get one using the kuma cli: `kuma notification list`";
                  default = { };
                  type = attrs;
                  example = {
                    applyExisting = true;
                    disableUrl = false;
                    discordChannelType = "channel";
                    discordUsername = "Uptime Kuma";
                    discordWebhookUrl = "https://discord.com/api/webhooks/1234567890123456789/foobarbaz";
                    isDefault = true;
                    name = "Discord Hook";
                    type = "discord";
                  };
                };
              };
            });
          };
          tags = mkOption {
            description = "List of generated autokuma tags";
            default = { };
            example = {
              my_tag = {
                name = "Foo";
                color = "#FF00FF";
              };
            };
            type = attrsOf (submodule {
              options = {
                name = mkOption {
                  description = "Name of the tag";
                  type = str;
                  example = "Foo";
                };
                color = mkOption {
                  description = "Color of the tag";
                  type = str;
                  example = "#FF00FF";
                };
              };
            });
          };
          monitors = mkOption {
            description = "List of generated autokuma monitors (uses a few autokuma-specific properties, passes the rest to uptime kuma, see https://github.com/BigBoot/AutoKuma/blob/master/ENTITY_TYPES.md)";
            default = { };
            example = {
              my_service = {
                type = "http";
                name = "My service";
                url = "https://example.com";
              };
            };
            type = attrs;
          };
          envFile = mkOption {
            description = "Path to environment file for this autokuma instance, should not be a path inside the nix store, should use a secrets manager like sops(-nix)/agenix";
            default = null;
            type = nullOr path;
            example = "/run/secrets/autokuma.env";
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    users = foldl' (
      acc: instance:
      let
        user = if instance.user != null then instance.user else cfg.defaultUser;
        group = if instance.group != null then instance.group else cfg.defaultGroup;
      in
      mergeAttrs acc {
        users.${user} = mkDefault {
          isSystemUser = true;
          inherit group;
        };
        groups.${group} = { };
      }
    ) { } (attrValues cfg.instances);

    infra.backup.jobs.state.paths = mapAttrsToList (name: _: "/var/lib/autokuma-${name}") cfg.instances;

    systemd.services = mapAttrs' (
      name: instance:
      let
        serviceName = "autokuma-${name}";
        dir = "/var/lib/autokuma-${name}";
        monitorsDir = "${dir}/monitors";
        monitorsTOML = map ({ name, value }: format.generate "${name}.toml" value) (
          attrsToList (mkMonitorAttrs instance)
        );
        settings = {
          static_monitors = monitorsDir;
        }
        // (recursiveUpdate (validTOML cfg.defaultSettings) (validTOML instance.settings));
        configTOML = format.generate "${serviceName}.toml" settings;
      in
      nameValuePair serviceName {
        description = "AutoKuma ${name}";
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        # This should not be needed, but monitor files should be writable for some reason...
        preStart = ''
          mkdir -p ${monitorsDir} | true
          rm -rf ${monitorsDir}/*
          rm -f ${dir}/autokuma.toml
          cp -f ${configTOML} ${dir}/autokuma.toml
          chmod 664 ${dir}/autokuma.toml
          ${map (path: "cp ${path} ${monitorsDir}/${trimHash path}") monitorsTOML |> concatStringsSep "\n"}
          ${
            map (
              path: "cp ${path} ${monitorsDir}/${baseNameOf path |> removeSuffix ".toml"}.toml"
            ) instance.additionalMonitorFiles
            |> concatStringsSep "\n"
          }
        '';
        path = with pkgs; [ cacert ];
        environment = {
          XDG_CONFIG_HOME = dir; # yes this is required
          RUST_LOG = instance.logLevel;
        };
        serviceConfig = {
          Type = "simple";
          StateDirectory = "autokuma-${name}";
          StateDirectoryMode = "750";
          User = if instance.user != null then instance.user else cfg.defaultUser;
          ExecStart = getExe cfg.package;
          EnvironmentFile = if instance.envFile != null then instance.envFile else cfg.defaultEnvFile;
          WorkingDirectory = dir;
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
          ReadWritePaths = dir;
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
        };
      }
    ) (filterAttrs (_: value: value.enable) cfg.instances);
  };
}
