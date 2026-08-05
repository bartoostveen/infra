{ inputs, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  imports = [ inputs.meshcoretomqtt.nixosModules.default ];

  services.mctomqtt = {
    enable = true;
    package = inputs.meshcoretomqtt.packages.${system}.default;
    iata = "ENS";
    serialPorts = [ "/dev/ttyACM0" ];
    defaults = {
      letsmesh-us.enable = false;
      letsmesh-eu.enable = true;
    };
  };
}
