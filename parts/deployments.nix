{ wireguard, ... }:

{
  deployments = {
    groups = rec {
      desktop = [
        "bart-laptop-new"
        "bart-pc"
      ];
      server = [
        "atlas"
        "vector"
        "prism"
        "bart-server"
      ];
      x86_64-linux = desktop ++ [
        "vector"
        "bart-server"
      ];
    };

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
      prism = {
        sshUser = "root";
        ip = "delta.bartoostveen.nl";
        system = "aarch64-linux";
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
