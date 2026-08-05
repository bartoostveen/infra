{ config, ... }:

let
  domain = "vault.bartoostveen.nl";
  email = "vault@bartoostveen.nl";
in
{
  services.vaultwarden = {
    enable = true;
    configureNginx = true;
    inherit domain;
    dbBackend = "postgresql";
    configurePostgres = true;
    environmentFile = config.sops.secrets.vaultwarden-env.path;
    config = {
      SIGNUPS_ALLOWED = false;

      SMTP_HOST = "mx.bartoostveen.nl";
      SMTP_PORT = 25;
      SMTP_SECURITY = "starttls";
      SMTP_FROM = email;
      SMTP_USERNAME = email;
      SMTP_FROM_NAME = "Bart Oostveen's vault";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
  };

  sops.secrets.vaultwarden-env = {
    owner = "vaultwarden";
    group = "vaultwarden";
    mode = "0440";
    sopsFile = ../../../../secrets/vaultwarden.env.vector.secret;
    format = "binary";
    restartUnits = [ "vaultwarden.service" ];
  };
}
