{ lib, ... }:

{
  # TODO: add back
  # services.resolved.enable = lib.mkForce false;
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
