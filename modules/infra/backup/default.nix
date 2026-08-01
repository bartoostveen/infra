{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.infra.backup;

  inherit (lib)
    # keep-sorted start
    attrsToList
    filterAttrs
    mergeAttrsList
    mkEnableOption
    mkIf
    mkOption
    tryEval
    types
    # keep-sorted end
    ;

  inherit (types)
    # keep-sorted start
    attrsOf
    lines
    listOf
    nullOr
    path
    port
    str
    submodule
    # keep-sorted end
    ;

  nixosModule =
    filterAttrs (_: j: j.enable) cfg.jobs
    |> attrsToList
    |> map (
      { name, value }:

      {
        assertions = [
          {
            assertion = value.paths != [ ];
            message = "You cannot backup an empty list of paths! Disable backups completely or add paths to back up!";
          }
        ];

        programs.ssh.knownHosts."${
          if value.port != 22 then "[${value.host}]:${value.port}" else value.host
        }".publicKey =
          value.hostPublicKey;

        systemd.services."borgbackup-job-${name}" = {
          wants = value.wantedUnits;
          after = value.wantedUnits;
        };

        systemd.timers."borgbackup-job-${name}".timerConfig = {
          # spread backups
          RandomizedDelaySec = "1h";
          FixedRandomDelay = true;
        };

        services.borgbackup.jobs.${name} = {
          doInit = true;
          startAt = "daily";

          prune.keep = {
            daily = 7;
            weekly = 4;
            monthly = 3;
          };

          inherit (value)
            paths
            exclude
            preHook
            postHook
            ;

          repo = "${value.user}@${value.host}:${config.networking.fqdn}";
          environment.BORG_RSH = "ssh -p ${toString value.port} -i ${value.sshKeyFile}";
          extraInitArgs = lib.optionalString (value.quota != null) "--storage-quota ${value.quota}";
          encryption = {
            mode = "repokey-blake2";
            passCommand = "cat ${value.secretKeyFile}";
          };
          compression = "auto,zstd";
          extraCreateArgs = "--stats";
        };

        environment.systemPackages = [
          (
            with pkgs;
            writeShellApplication {
              name = "borg-${name}";
              runtimeInputs = [ borgbackup ];
              runtimeEnv = config.systemd.services."borgbackup-job-${name}".environment;
              text = ''
                borg "$@"
              '';
            }
          )
        ];
      }
    )
    |> mergeAttrsList;
in
{
  imports = [
    # keep-sorted start
    ./defaults.nix
    ./mysql.nix
    ./postgres.nix
    # keep-sorted end
  ];

  options.infra.backup = {
    enable = mkEnableOption "server backups (push side, configure borg credentials on destination manually)";
    defaults = {
      sshKeyFile = mkOption {
        type = nullOr path;
        example = "/run/secrets/borg/ssh-key";
        description = "Default path to the SSH key required to access the remote host";
        default = null;
      };

      secretKeyFile = mkOption {
        type = nullOr path;
        example = "/run/secrets/borg/borg-secret";
        description = "Default path to the secret used to encrypt backups in the repository";
        default = null;
      };
    };
    jobs = mkOption {
      description = "Backup jobs to run on a node";
      default = { };
      type = attrsOf (submodule {
        options = {
          enable = (mkEnableOption "this job") // {
            default = true;
          };

          user = mkOption {
            type = str;
            description = "Username for the SSH remote host";
            default = "backshots";
          };

          host = mkOption {
            type = str;
            description = "Hostname of the SSH remote host";
          };

          hostPublicKey = mkOption {
            type = str;
            description = "Public SSH host key of the remote host";
            default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/l3xTETEXqMK2CW6TLs93mwlyH3q6hPwPGUbG+c9QO";
          };

          port = mkOption {
            type = port;
            default = 22;
            description = "Port of the SSH remote host";
          };

          sshKeyFile = mkOption {
            type = path;
            example = "/run/secrets/borg/ssh-key";
            description = "Path to the SSH key required to access the remote host";
            default = cfg.defaults.sshKeyFile;
          };

          secretKeyFile = mkOption {
            type = path;
            example = "/run/secrets/borg/borg-secret";
            description = "Path to the secret used to encrypt backups in the repository";
            default = cfg.defaults.secretKeyFile;
          };

          quota = mkOption {
            type = nullOr str;
            default = null;
            example = "90G";
            description = "Quota for the borg repository";
          };

          paths = mkOption {
            type = listOf path;
            default = [ ];
            description = "Paths to include in the backup";
          };

          exclude = mkOption {
            type = listOf path;
            default = [ ];
            description = "Paths to exclude in the backup";
          };

          preHook = mkOption {
            type = lines;
            default = "";
            description = "Shell commands to run before the backup";
          };

          postHook = mkOption {
            type = lines;
            default = "";
            description = "Shell commands to run after the backup";
          };

          wantedUnits = mkOption {
            type = listOf str;
            default = [ ];
            description = "List of units to require before starting the backup";
          };
        };
      });
    };
  };

  config = mkIf cfg.enable (
    let
      # This is way too cursed. The old solution was better but nix decided not to cooperate
      # adios(-flake) solves this (callable modules). downside: options harder to document
      eval = tryEval {
        assertions = nixosModule.assertions or { };
        programs = nixosModule.programs or { };
        systemd = nixosModule.systemd or { };
        services = nixosModule.services or { };
        environment = nixosModule.environment or { };
      };
    in
    if eval.success then
      eval.value
    else
      {
        warnings = [
          "Tried to evaluate the infra.backup module, but it is not enabled (correctly!). Consider disabling, ignore this if importing for documentation purposes."
        ];
      }
  );
}
