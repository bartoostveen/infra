{ config, ... }:

{
  virtualisation.oci-containers.containers.tascheduling-db = {
    image = "postgres:18";
    environment = {
      POSTGRES_USER = "tascheduling";
      POSTGRES_DB = "tascheduling";
    };
    environmentFiles = [ config.sops.secrets.tascheduling-db-env.path ];
    volumes = [ "tascheduling-db-data:/var/lib/postgresql" ];
    ports = [ "5433:5432" ];
  };

  sops.secrets.tascheduling-db-env = {
    sopsFile = ../../../../secrets/tascheduling-db.env.bart-server.secret;
    format = "binary";
    restartUnits = [ "podman-tascheduling-db.service" ];
  };
}
