{ inputs, ... }:

{
  imports = [
    inputs.srvos.nixosModules.mixins-telegraf
  ];

  services.prometheus.exporters = {
    postgres.enable = true;
    nginx.enable = true;
    nginxlog.enable = true;
    systemd.enable = true;
    node.enable = true;
  };
}
