let
  redisSocket = "/run/redis-anubis/redis.sock";
in
{
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "anubis" ];
  services.anubis.defaultOptions = {
    settings = {
      SERVE_ROBOTS_TXT = true;
      WEBMASTER_EMAIL = "anubis@bartoostveen.nl";
    };
    policy.settings.store = {
      backend = "valkey";
      parameters.url = "unix://${redisSocket}";
    };
  };

  services.redis.servers.anubis = {
    enable = true;
    user = "anubis";
    unixSocket = redisSocket;
    unixSocketPerm = 770;
  };

  users = {
    users.anubis = {
      isSystemUser = true;
      group = "anubis";
    };
    groups.anubis = { };
  };
}
