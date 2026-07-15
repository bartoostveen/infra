{ lib, config, ... }:

{
  # TODO: make less ugly (https://github.com/nix-community/srvos/blob/77faea4aed26379aa30304850dd0ef2b6f2dfe28/nixos/common/networking.nix#L25)
  services.resolved.enable = lib.mkForce false;
  systemd.services.systemd-resolved.enable = lib.mkForce false;
  services.kresd.enable = lib.mkForce false;

  services.unbound = {
    enable = true;
    localControlSocketPath = "/run/unbound/control.sock";
    settings = {
      server = {
        rrset-cache-size = "128M";
        msg-cache-size = "128M";
        discard-timeout = 4800;
        extended-statistics = true;
        log-servfail = true;
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "1.1.1.1"
            "1.0.0.1"
            "8.8.8.8"
            "8.8.4.4"
          ];
        }
      ];
    };
  };

  services.prometheus.exporters.unbound = {
    enable = true;
    unbound.host = "unix://${config.services.unbound.localControlSocketPath}";
  };

  systemd.services.prometheus-unbound-exporter.serviceConfig.SupplementaryGroups = [ "unbound" ];
}
