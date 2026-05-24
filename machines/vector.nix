{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./vector.disk-config.nix

    inputs.nixos-facter-modules.nixosModules.facter

    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd

    ../modules/wireguard.nix

    # keep-sorted start
    ../modules/infra/alertmanager.nix
    ../modules/infra/alloy.nix
    ../modules/infra/autokuma-config.nix
    ../modules/infra/backup
    ../modules/infra/common.nix
    ../modules/infra/fail2ban.nix
    ../modules/infra/forgejo-actions.nix
    ../modules/infra/git.nix
    ../modules/infra/networking.nix
    ../modules/infra/nginx.extra.nix
    ../modules/infra/nginx.nix
    ../modules/infra/nix.nix
    ../modules/infra/php.nix
    ../modules/infra/podman.nix
    # keep-sorted end

    # keep-sorted start
    ../modules/infra/system-specific/vector/auth.nix
    ../modules/infra/system-specific/vector/cloud.nix
    ../modules/infra/system-specific/vector/mail
    ../modules/infra/system-specific/vector/monitoring.nix
    ../modules/infra/system-specific/vector/onboarding.nix
    ../modules/infra/system-specific/vector/renovate.nix
    ../modules/infra/system-specific/vector/wordpress.nix
    # keep-sorted end
  ];

  facter.reportPath = ./vector.json;
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:1c19:1cd2::1/128";

  infra.wireguard.enable = true;

  infra.forgejo-actions = {
    enable = true;
    amount = 2;
  };

  infra.backup = {
    enableDefaults = true;
    postgres.enable = true;
    mysql.enable = true;
  };

  system.stateVersion = "26.11";
}
