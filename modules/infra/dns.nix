{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (lib) mkIf;
in
{
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
      forward-zone = mkIf (system != "x86_64-linux") [
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
