{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# TODO: this module is not really neccesary anymore
let
  inherit (builtins)
    readFile
    ;

  inherit (lib)
    # keep-sorted start
    genAttrs
    genAttrs'
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    nameValuePair
    optionals
    range
    trim
    types
    # keep-sorted end
    ;

  inherit (types)
    # keep-sorted start
    attrs
    ints
    listOf
    str
    # keep-sorted end
    ;

  cfg = config.infra.forgejo-actions;
  runners = range 0 (cfg.amount - 1);

  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  options.infra.forgejo-actions = {
    enable = mkEnableOption "Forgejo Actions runner";
    package = mkPackageOption pkgs "forgejo-runner" { };
    amount = mkOption {
      description = "The amount of forgejo actions workers";
      type = ints.positive;
      default = 4;
      example = 2;
    };
    url = mkOption {
      description = "The URL of the Forgejo host";
      type = str;
      default = inputs.self.nixosConfigurations.sentinel.config.services.forgejo.settings.server.ROOT_URL;
      example = "https://git.bartoostveen.nl";
    };
    labels = mkOption {
      description = "Labels for all actions runners";
      type = listOf str;
      default = [ ];
      example = [ ];
    };
    environment = mkOption {
      description = "Systemd options for ALL runners";
      type = attrs;
      default = { };
      example = { };
    };
    systemdDependencies = mkOption {
      description = "List of systemd requires/wants/after units for all services";
      type = listOf str;
      default = [ "sops-install-secrets.service" ];
      example = [ "forgejo.service" ];
    };
  };

  config = mkIf cfg.enable {
    infra.forgejo-actions.labels = [
      "native-${system}:host"
      "${config.networking.hostName}:host"
    ]
    ++ optionals config.virtualisation.podman.enable [
      "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-24.04"
      "nix:docker://docker.io/nixos/nix:2.32.8"
      "lix:docker://git.toostveen.nl/tom/lix-with-node:latest"
    ]
    ++ (map (feat: "${feat}:host") config.nix.settings.system-features)
    ++ (map (sys: "emulated-${sys}:host") config.boot.binfmt.emulatedSystems);

    services.forgejo-runner = {
      inherit (cfg) package;
      instances = genAttrs' (map toString runners) (
        n:

        nameValuePair "runner${n}" {
          enable = true;
          hostPackages = with pkgs; [
            # keep-sorted start
            bash
            config.nix.package
            coreutils
            curl
            gawk
            gitFull
            gnupg
            gnused
            jq
            nodejs
            openssh
            unzip
            wget
            which
            zip
            # keep-sorted end
          ];
          secrets.server.connections.default.token_url =
            config.sops.secrets."forgejo-runner-token-runner${n}.${config.networking.hostName}".path;
          settings = {
            server.connections.default = {
              inherit (cfg) url;
              uuid =
                readFile ../../secrets/forgejo/forgejo-runner-uuid-runner${n}.${config.networking.hostName} |> trim;
            };
            runner = {
              envs = cfg.environment;
              inherit (cfg) labels;
            };
          };
        }
      );
    };

    systemd.services = genAttrs (map (n: "gitea-runner-runner${toString n}.service") runners) (_: {
      inherit (cfg) environment;
      serviceConfig = {
        requires = cfg.systemdDependencies;
        wants = cfg.systemdDependencies;
        after = cfg.systemdDependencies;
      };
    });

    virtualisation.podman.enable = mkDefault true;

    users.users.gitea-runner = {
      isSystemUser = true;
      group = "gitea-runner";
    };
    users.groups.gitea-runner = { };

    sops.secrets = genAttrs' (map toString runners) (
      n:

      let
        name = "forgejo-runner-token-runner${n}.${config.networking.hostName}";
      in
      nameValuePair name {
        sopsFile = ../../secrets/forgejo/${name}.secret;
        owner = "gitea-runner";
        group = "gitea-runner";
        mode = "0400";
        format = "binary";
        restartUnits = [ "forgejo-runner-runner${n}.service" ];
      }
    );
  };
}
