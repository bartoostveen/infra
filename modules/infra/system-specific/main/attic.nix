{ pkgs, config, ... }:

let
  vHost = "attic.bartoostveen.nl";
  serverAliases = [ "cache.bartoostveen.nl" ];

  user = "atticd";
in
{
  services.atticd = {
    enable = true;
    mode = "monolithic";
    inherit user;
    group = user;

    environmentFile = config.sops.secrets.attic-env.path;

    settings = {
      allowed-hosts = [ vHost ] ++ serverAliases;
      api-endpoint = "https://${vHost}/";
      listen = "127.0.0.1:64153";
      max-nar-info-size = 1048576;
      require-proof-of-possession = true;

      chunking = {
        avg-size = 65536;
        max-size = 262144;
        min-size = 16384;
        nar-size-threshold = 65536;
      };
      compression = {
        level = 8;
        type = "zstd";
      };
      database.url = "postgresql:///${user}?host=/run/postgresql";
      garbage-collection = {
        default-retention-period = "2 months";
        interval = "1 day";
      };
    };
  };

  infra.backup.jobs.state.paths = [ config.services.atticd.settings.storage.path ];

  users.users.${user} = {
    isSystemUser = true;
    group = user;
  };
  users.groups.${user} = { };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ user ];
    ensureUsers = [
      {
        name = user;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  services.nginx.virtualHosts.${vHost} = {
    enableACME = true;
    forceSSL = true;

    inherit serverAliases;

    locations."/" = {
      proxyPass = "http://${config.services.atticd.settings.listen}";
      proxyWebsockets = true;
      rateLimit.burst = 250;
      extraConfig = ''
        client_max_body_size 0;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_buffers 32 8k;
        proxy_buffer_size 16k;
        proxy_busy_buffers_size 24k;
      '';
    };
  };

  sops.secrets.attic-env = {
    group = user;
    owner = user;
    mode = "0600";

    sopsFile = ../../../../secrets/attic.env.bart-server.secret;
    restartUnits = [ "atticd.service" ];
    format = "binary";
  };

  environment.systemPackages = with pkgs; [
    attic-client
  ];
}
