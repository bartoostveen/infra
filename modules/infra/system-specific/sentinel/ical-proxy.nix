{
  inputs,
  inputs',
  config,
  ...
}:

let
  redisSocket = "/run/redis-ical-proxy/redis.sock";
in
{
  imports = [ inputs.ical-proxy.nixosModules.default ];

  services.ical-proxy = {
    enable = true;
    package = inputs'.ical-proxy.packages.default;
    settings = {
      port = 6968;
      redis_url = "redis+unix://${redisSocket}";
    };
  };

  systemd.services.ical-proxy = {
    requires = [ "redis-ical-proxy.service" ];
    wants = [ "redis-ical-proxy.service" ];
    after = [ "redis-ical-proxy.service" ];
  };

  users.users.ical-proxy = {
    isSystemUser = true;
    group = "ical-proxy";
    description = "ical-proxy service user";
  };
  users.groups.ical-proxy = { };

  services.redis.servers.ical-proxy = {
    enable = true;
    user = "ical-proxy";
    unixSocket = redisSocket;
    unixSocketPerm = 770;
  };

  services.nginx.virtualHosts."ical-proxy.bartoostveen.nl" = {
    serverAliases = [ "calendarthing.omeduostuurcentenneef.nl" ];
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:${toString config.services.ical-proxy.settings.port}";
  };
}
