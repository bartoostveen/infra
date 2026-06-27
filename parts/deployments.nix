{
  # TODO: wireguard dns
  deployments = {
    nixos = {
      bart-server = {
        sshUser = "root";
        ip = "bartoostveen.nl";
      };
      bart-laptop-new = {
        sshUser = "bart";
        ip = "10.0.0.2"; # TODO: remove
      };
      bart-pc = {
        sshUser = "bart";
        ip = "10.0.0.7"; # TODO: remove
      };
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
