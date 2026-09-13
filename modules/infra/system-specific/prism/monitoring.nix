{ inputs, ... }:

{
  imports = [
    inputs.srvos.nixosModules.mixins-telegraf
  ];

  services.prometheus.exporters = {
    systemd.enable = true;
    node.enable = true;
  };
}
