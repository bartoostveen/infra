{ inputs, ... }:

{
  imports = [ inputs.vert-nix.nixosModules.default ];

  services.vert = {
    enable = true;
    hostName = "vert.vitune.app";
    nginx = {
      enable = true;
      enableACME = true;
      forceSSL = true;
    };
  };
}
