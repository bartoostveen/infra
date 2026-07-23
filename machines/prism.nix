{ inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./prism.disk-config.nix

    inputs.nixos-facter-modules.nixosModules.facter
    inputs.srvos.nixosModules.server

    ../modules/wireguard.nix

    # keep-sorted start
    ../modules/infra/alertmanager.nix
    ../modules/infra/alloy.nix
    ../modules/infra/anubis.nix
    # ../modules/infra/autokuma-config.nix
    ../modules/infra/backup
    ../modules/infra/common.nix
    ../modules/infra/dns.nix
    ../modules/infra/fail2ban.nix
    ../modules/infra/forgejo-actions.nix
    ../modules/infra/git.nix
    # ../modules/infra/hydra/builder.nix
    ../modules/infra/networking.nix
    ../modules/infra/nginx.extra.nix
    ../modules/infra/nginx.nix
    ../modules/infra/nix.nix
    ../modules/infra/php.nix
    ../modules/infra/podman.nix
    # keep-sorted end

    # keep-sorted start
    # keep-sorted end
  ];

  facter.reportPath = ./prism.json;
  networking.firewall.checkReversePath = "loose";
  systemd.network.networks."10-uplink" = {
    matchConfig.Name = "enp0s6";
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.UseRoutes = true;
    routes = [
      {
        routeConfig = {
          Gateway = "_dhcp4";
          GatewayOnLink = true;
        };
      }
    ];
  };

  infra.wireguard.enable = true;

  infra.forgejo-actions = {
    enable = true;
    amount = 2;
  };

  infra.backup = {
    enableDefaults = true;
    # postgres.enable = true;
    # mysql.enable = true;
  };

  system.stateVersion = "26.11";
}
