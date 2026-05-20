{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkDefault
    types
    genAttrs
    genAttrs'
    nameValuePair
    mkIf
    range
    ;
  inherit (types)
    listOf
    ints
    str
    attrs
    ;

  cfg = config.infra.forgejo-actions;
  runners = range 0 (cfg.amount - 1);
in
{
  options.infra.forgejo-actions = {
    enable = mkEnableOption "fj actions";
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
      default =
        inputs.self.nixosConfigurations.bart-server.config.services.forgejo.settings.server.ROOT_URL;
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
  # TODO: add prestart provision script?
  config = mkIf cfg.enable {
    infra.forgejo-actions.labels = [
      "docker:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
      "nix:docker://docker.io/nixos/nix:2.32.8"
      "lix:docker://git.toostveen.nl/tom/lix-with-node:latest"
      "native-${pkgs.stdenv.system}:host"
      "${config.networking.hostName}:host"
    ]
    ++ (map (feat: "${feat}:host") config.nix.settings.system-features)
    ++ (map (sys: "emulated-${sys}:host") config.boot.binfmt.emulatedSystems);

    services.gitea-actions-runner = {
      inherit (cfg) package;
      instances = genAttrs' (map toString runners) (
        n:
        nameValuePair "runner${n}" {
          enable = true;
          name = "${config.networking.fqdn}-runner${n}";
          inherit (cfg) url labels;
          tokenFile =
            config.sops.secrets."forgejo-runner-token-${config.networking.hostName}-runner${n}".path;
          hostPackages = with pkgs; [
            bash
            coreutils
            curl
            gawk
            gnused
            gnupg
            nodejs
            wget
            jq
            gitFull
            config.nix.package
            openssh
          ];
          settings.runner.envs = cfg.environment;
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

    # TODO: these secrets are currently identical, move to connections instead
    sops.secrets = genAttrs' (map toString runners) (
      n:
      let
        name = "forgejo-runner-token-${config.networking.hostName}-runner${n}";
      in
      nameValuePair name {
        # sopsFile = ../../secrets/${name}.secret;
        sopsFile = ../../secrets/forgejo-runner-token.secret;
        owner = "gitea-runner";
        group = "gitea-runner";
        mode = "0400";
        format = "binary";
        restartUnits = [ "gitea-runner-runner${n}.service" ];
      }
    );
  };
}
