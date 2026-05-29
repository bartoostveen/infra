{
  pkgs,
  # lib,
  # inputs,
  # config,
  # wireguard,
  ...
}:

let
  domain = "tcsdiscord.bartoostveen.nl";
  name = "tcs-bot";
  # port = 6769;
  dbUser = name;
  dbPassword = "Waarom moet dit, dit is echt super nutteloos aangezien de database niet exposed is, maar hee aan de ene aardling die dit leest, goeie dagschotel!";
  # env = {
  #   CANVAS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
  #   REDIS_CONNECTION_STRING = "${name}-redis:6379";
  #   DATABASE_CONNECTION_STRING = "jdbc:postgresql://${name}-db:5432/${name}";
  #   DATABASE_USERNAME = dbUser;
  #   DATABASE_PASSWORD = dbPassword;
  #   PORT = toString port;
  #   HOSTNAME = "https://${domain}";
  #   ENVIRONMENT = "PRODUCTION";
  # };
  # pkg = inputs.tcs-bot.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # dockerImage = pkgs.dockerTools.streamLayeredImage {
  #   inherit name;
  #   tag = pkg.version;
  #   contents = with pkgs; [
  #     pkg
  #     busybox
  #     cacert
  #     curl
  #     coreutils-full
  #     bashInteractive
  #   ];
  #   config.Cmd = [ "/bin/${pkg.pname}" ];
  # };
  backupDir = "/srv/${name}-backups";
in
{
  virtualisation.oci-containers.containers = {
    # ${name} = {
    #   image = "localhost/${name}:${pkg.version}";
    #   imageStream = dockerImage;
    #   environment = env;
    #   environmentFiles = [ config.sops.secrets.tcs-bot-env.path ];
    #   ports = [
    #     "127.0.0.1:${toString port}:${toString port}"
    #     "${wireguard.primaryIpOf config.networking.hostName}:${toString port}:${toString port}"
    #   ];
    # };
    "${name}-db" = {
      image = "postgres:latest";
      environment = {
        POSTGRES_USER = dbUser;
        POSTGRES_PASSWORD = dbPassword;
        POSTGRES_DB = name;
      };
      volumes = [ "${name}-db-data:/var/lib/postgresql" ];
    };
    "${name}-redis" = {
      image = "valkey/valkey:latest";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations = {
      "/".root = pkgs.writeTextDir "/index.html" (
        builtins.readFile ./tcs-bot-temporarily-unavailable.html
      );
      # "/".proxyPass = "http://localhost:${toString port}";
      # "/metrics".extraConfig = "return 404;";
    };
  };

  # infra.extraScrapeConfigs.tcs-bot = {
  #   inherit port;
  # };

  # sops.secrets.tcs-bot-env = {
  #   format = "binary";
  #   sopsFile = ../../../../../secrets/tcs-bot.env.bart-server.secret;
  #   restartUnits = [ "podman-tcs-bot.service" ];
  # };

  # systemd.timers."${name}-db-backup" = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #     Unit = "${name}-db-backup.service";
  #   };
  # };

  # systemd.services."${name}-db-backup" = {
  #   script = ''
  #     set -eu
  #     mkdir -p ${backupDir}
  #     chown -R root:users ${backupDir}
  #     ${lib.getExe' pkgs.postgresql_18 "pg_dump"} \
  #       -h $(${lib.getExe pkgs.podman} container inspect -f '{{.NetworkSettings.IPAddress}}' ${name}-db) \
  #       -d ${name} \
  #       -U "${dbUser}" > ${backupDir}/dump-$(date +%Y-%m-%d--%H-%M-%S).bak
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = "root";
  #   };
  #   environment.PGPASSWORD = dbPassword;
  # };

  services.copyparty.volumes."/${name}-backups" = {
    access.A = "adm";
    path = backupDir;
  };
}
