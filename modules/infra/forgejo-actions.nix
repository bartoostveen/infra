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
  inherit (types) listOf ints str;

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
      default = [
        "nix"
        "system:${pkgs.stdenv.system}"
      ];
      example = [ "big" ];
    };
    # TODO: all systemd service options through submodule type
    systemdDependencies = mkOption {
      description = "List of systemd requires/wants/after units for all services";
      type = listOf str;
      default = [ "sops-install-secrets.service" ];
      example = [ "forgejo.service" ];
    };
  };
  # TODO: add prestart provision script?
  config = mkIf cfg.enable {
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
        }
      );
    };

    systemd.services = genAttrs (map (n: "gitea-runner-runner${toString n}.service") runners) (_: {
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
