{
  config,
  lib,
  inputs,
  ...
}:

let
  inherit (lib)
    mkDefault
    head
    getExe
    cli
    ;
  inherit (cli) toCommandLineShellGNU;

  redisSocket = "/run/redis-forgejo/redis.sock";
  redisHost = "network=unix addr=${redisSocket}";
  anubisMetricsPort = 11023;
in
{
  services.forgejo = {
    enable = true;
    lfs.enable = true;
    database = {
      createDatabase = true;
      type = "postgres";
    };
    settings = {
      server = rec {
        DOMAIN = "git.bartoostveen.nl";
        ROOT_URL = "https://${DOMAIN}/";
        HTTP_PORT = 11022;
        SSH_PORT = head config.services.openssh.ports;
      };
      actions.ENABLED = true;
      service.DISABLE_REGISTRATION = true;
      mailer = rec {
        ENABLED = true;
        PROTOCOL = "smtps";
        SMTP_ADDR = inputs.self.nixosConfigurations.bart-server.config.mailserver.systemDomain;
        SMTP_PORT = 465;
        USER = "git@${SMTP_ADDR}";
        PASSWD_URI = "file:${config.sops.secrets.git-email-password.path}";
        FROM = "Bart's Forgejo <${USER}>";
      };
      "email.incoming" = rec {
        ENABLED = true;
        HOST = inputs.self.nixosConfigurations.bart-server.config.mailserver.systemDomain;
        PORT = 993;
        USERNAME = "git@${HOST}";
        PASSWORD_URI = "file:${config.sops.secrets.git-email-password.path}";
        REPLY_TO_ADDRESS = "git+%{token}@${HOST}";
        USE_TLS = true;
      };
      cache = {
        ADAPTER = "redis";
        HOST = redisHost;
      };
      session = {
        PROVIDER = "redis";
        PROVIDER_CONFIG = redisHost;
      };
      cron.ENABLED = true;
      metrics.ENABLED = true;
      packages.ENABLED = false;
    };
    # TODO: restore script
    dump.enable = true; # exists in statedir by default, so should get backed up
  };

  systemd.services.forgejo =
    let
      dependencies = [ "redis-forgejo.service" ];
    in
    {
      requires = dependencies;
      wants = dependencies;
      after = dependencies;
      preStart = ''
        ${getExe config.services.forgejo.package} admin user create ${
          toCommandLineShellGNU { } {
            email = "bart@bartoostveen.nl";
            username = "bart";
            admin = true;
          }
        } --password "$(tr -d '\n' < ${config.sops.secrets.forgejo-admin-password.path})" || true
      '';
    };

  services.redis.servers.forgejo = {
    enable = true;
    user = "forgejo";
    unixSocket = redisSocket;
    unixSocketPerm = 770;
  };

  # TODO: simplify
  services.anubis.instances.forgejo.settings = {
    BIND = "/run/anubis/anubis-forgejo/anubis-forgejo.sock";
    TARGET = "http://localhost:${toString config.services.forgejo.settings.server.HTTP_PORT}";
    METRICS_BIND = "0.0.0.0:${toString anubisMetricsPort}";
    METRICS_BIND_NETWORK = "tcp";
  };

  services.nginx.virtualHosts.${config.services.forgejo.settings.server.DOMAIN} = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://unix://${config.services.anubis.instances.forgejo.settings.BIND}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 0;
          proxy_buffering off;
          proxy_request_buffering off;
          proxy_buffers 32 8k;
          proxy_buffer_size 16k;
          proxy_busy_buffers_size 24k;
        '';
      };
      "/metrics".extraConfig = "return 404;";
    };
  };

  services.openssh.enable = mkDefault true;
  virtualisation.podman.enable = mkDefault true;

  infra = {
    backup.jobs.state.paths = [ config.services.forgejo.stateDir ];
    extraScrapeConfigs = {
      forgejo.port = config.services.forgejo.settings.server.HTTP_PORT;
      forgejo-anubis.port = anubisMetricsPort;
    };
  };

  sops.secrets.forgejo-admin-password = {
    sopsFile = ../../../../secrets/forgejo-admin-password.secret;
    owner = "forgejo";
    group = "forgejo";
    mode = "0400";
    format = "binary";
    restartUnits = [ "forgejo.service" ];
  };

  sops.secrets.git-email-password = {
    sopsFile = ../../../../secrets/email-passwords/git.secret;
    owner = "forgejo";
    group = "forgejo";
    mode = "0600";
    format = "binary";
    restartUnits = [ "forgejo.service" ];
  };
}
