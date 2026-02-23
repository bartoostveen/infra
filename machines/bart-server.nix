{ inputs, lib, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter

    ./server.disk-config.nix
    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd

    ../containers/tcs-bot.nix
    ../containers/web.nix

    ../modules/infra/anubis.nix
    ../modules/infra/attic.nix
    ../modules/infra/authentik.nix
    ../modules/infra/autokuma.nix
    ../modules/infra/common.nix
    ../modules/infra/continuwuity.nix
    ../modules/infra/copyparty.nix
    ../modules/infra/fail2ban.nix
    ../modules/infra/git.nix
    ../modules/infra/ical-proxy.nix
    ../modules/infra/ircbounce.nix
    ../modules/infra/mailserver
    ../modules/infra/maubot.nix
    ../modules/infra/monitoring.nix
    ../modules/infra/nix.nix
    ../modules/infra/nginx.nix
    ../modules/infra/podman.nix
    ../modules/infra/search.nix
    ../modules/infra/tailscale.nix
    # ../modules/infra/vaultwarden.nix
    ../modules/infra/wordpress-test.nix
  ];

  facter.reportPath = ./bart-server.json;
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:c2c:2f66::1/128";

  networking.firewall.allowedTCPPorts = [
    80
    443
    22
  ];

  srvos.prometheus.ruleGroups.srvosAlerts.alertRules.UnusualDiskReadLatency.enable = false;

  infra.copyparty = {
    enable = true;
    acme = true;
  };

  services.nginx.virtualHosts."laptop.omeduostuurcentenneef.nl" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://100.64.0.8:6969/";
      proxyWebsockets = true;
    };
  };

  services.kresd.enable = lib.mkForce false;

  system.stateVersion = "26.05";
}
