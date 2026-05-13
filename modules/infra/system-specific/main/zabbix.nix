{
  config,
  pkgs,
  wireguard,
  ...
}:

let
  fqdn = "bartoostveen.nl";
  hostname = "zabbix.${fqdn}";
  set = pkgs.zabbix74;
in
{
  services.zabbixServer = {
    enable = true;
    package = set.server;
    database = {
      createLocally = true;
      type = "pgsql";
    };
    listen.ip = wireguard.primaryIpOf config.networking.hostName;
  };
  services.zabbixWeb = {
    enable = true;
    package = set.web;
    database.type = "pgsql";
    frontend = "nginx";
    inherit hostname;
    server = {
      address = config.services.zabbixServer.listen.ip;
      inherit (config.services.zabbixServer.listen) port;
    };
    nginx.virtualHost = {
      enableACME = true;
      forceSSL = true;
    };
  };
}
