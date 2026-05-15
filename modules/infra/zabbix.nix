{
  config,
  pkgs,
  wireguard,
  inputs,
  ...
}:

let
  host = "bart-server";
  server = wireguard.primaryIpOf host;
in
{
  services.zabbixAgent = {
    enable = true;
    package = pkgs.zabbix74.agent2;
    listen.ip = wireguard.primaryIpOf config.networking.hostName;
    inherit server;
    settings.ServerActive = "${server}:${
      toString inputs.self.nixosConfigurations.${host}.config.services.zabbixServer.listen.port
    }";
  };
}
