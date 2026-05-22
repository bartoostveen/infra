{ lib, inputs, ... }:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
    ./atlas.firmware.nix
    ./atlas.hardware.nix

    inputs.srvos.nixosModules.server

    # keep-sorted start
    ../modules/infra/system-specific/atlas/backshots.nix
    ../modules/infra/system-specific/atlas/mc2mqtt.nix
    ../modules/infra/system-specific/atlas/monitoring.nix
    # keep-sorted end

    # keep-sorted start
    ../modules/infra/alertmanager.nix
    ../modules/infra/alloy.nix
    ../modules/infra/backup
    ../modules/infra/common.nix
    ../modules/infra/forgejo-actions.nix
    ../modules/infra/git.nix
    ../modules/infra/networking.nix
    ../modules/infra/podman.nix
    ../modules/wireguard.nix
    # keep-sorted end
  ];

  srvos.boot.consoles = [ ];

  nix.channel.enable = lib.mkForce false;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  infra.forgejo-actions = {
    enable = true;
    amount = 1;
  };

  # normally we wouldn't do this on servers, but oh well
  networking.networkmanager.enable = true;
  networking.useNetworkd = true;

  # infra.copyparty.enable = true;
  infra.wireguard.enable = true;

  system.stateVersion = "26.05";
}
