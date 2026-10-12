{ inputs, pkgs, ... }:

{
  imports = [ inputs.bart-packages.nixosModules.meshcoretomqtt ];

  services.meshcoretomqtt = {
    enable = true;
    package = pkgs.local.meshcoretomqtt;
    settings = {
      general.iata = "ENS";
      serial.ports = [ "/dev/ttyACM0" ];
    };
    defaults.letsmesh-eu = true;
  };
}
