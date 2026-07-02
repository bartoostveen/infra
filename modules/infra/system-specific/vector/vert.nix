{ inputs, config, ... }:

{
  imports = [ inputs.vert-nix.nixosModules.default ];

  services.vert = {
    enable = true;
    environmentFile = config.sops.secrets.vert-env.path;
    hostName = "vert.vitune.app";
    nginx = {
      enable = true;
      enableACME = true;
      forceSSL = true;
    };
  };

  services.nginx.virtualHosts.${config.services.vert.hostName} = {
    rateLimit.burst = 100;
    connectionLimit.connections = 50;
  };

  systemd.services.vert.serviceConfig = {
    MemoryHigh = "2G";
    CPUQuota = "200%";
  };

  sops.secrets.vert-env = {
    sopsFile = ../../../../secrets/vert.env.vector.secret;
    owner = "vertd";
    group = "vertd";
    mode = "0440";
    restartUnits = [ "vertd.service" ];
    format = "binary";
  };
}
