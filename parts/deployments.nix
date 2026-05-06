{
  deployments = {
    nixos = {
      bart-server = {
        sshUser = "root";
        ip = "bartoostveen.nl";
      };
      bart-laptop-new.sshUser = "bart";
      bart-pc.sshUser = "bart";
      atlas = {
        sshUser = "root";
        system = "aarch64-linux";
        ip = "atlas-wg"; # "192.168.1.145";
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
        hostname = "bart-laptop-new";
      }
      {
        username = "bart";
        hostname = "bart-pc";
      }
    ];
  };
}
