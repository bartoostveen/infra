{ lib, ... }:

{
  # TODO: make less ugly (https://github.com/nix-community/srvos/blob/77faea4aed26379aa30304850dd0ef2b6f2dfe28/nixos/common/networking.nix#L25)
  services.resolved.enable = lib.mkForce false;
  systemd.services.systemd-resolved.enable = lib.mkForce false;
  services.kresd.enable = lib.mkForce false;

  services.unbound = {
    enable = true;
    settings = {
      server = {
        rrset-cache-size = "64M";
        msg-cache-size = "64M";
        discard-timeout = 4800;
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        }
      ];
    };
  };
}
