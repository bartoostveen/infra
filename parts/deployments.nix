{ wireguard, ... }:

{
  deployments = {
    nixos = {
      bart-server = {
        sshUser = "root";
        ip = "bart-server.bartoostveen.nl";
      };
      bart-laptop-new = {
        sshUser = "bart";
        ip = wireguard.primaryIpOf "bart-laptop-new";
      };
      bart-pc = {
        sshUser = "bart";
        ip = wireguard.primaryIpOf "bart-pc";
      };
      atlas = {
        sshUser = "root";
        system = "aarch64-linux";
        ip = wireguard.primaryIpOf "atlas";
      };
      vector = {
        sshUser = "root";
        ip = "vector.bartoostveen.nl";
      };
    };

    extraNixOSConfigurations = {
      installer = { };
      minimal-sd = { };
    };

    home = [
      {
        username = "bart";
        sshUser = "bart";
        hostname = "bart-laptop-new";
      }
      {
        username = "bart";
        sshUser = "bart";
        hostname = "bart-pc";
      }
    ];
  };
}
