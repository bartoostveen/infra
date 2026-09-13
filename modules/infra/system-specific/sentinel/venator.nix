{
  config,
  inputs,
  pkgs,
  ...
}:

let
  port = 8449;
  domain = "venator.omeduostuurcentenneef.nl";
  federationDomain = "server.${domain}";
in
{
  imports = [ inputs.bart-packages.nixosModules.venator ];

  services.venator = {
    enable = true;
    package = pkgs.local.venator;
    configurePostgres = true;
    enableWrapper = true;
    settings = {
      registration = {
        admin_pre_shared_secret_file = config.sops.secrets.venator-admin-psk.path;
        peppering.pepper_file = config.sops.secrets.venator-pepper.path;
      };
      server_name = domain;
      listeners = [
        {
          inherit port;
          tls = false;
        }
      ];
      well_known.client = "https://${federationDomain}";
    };
  };

  systemd.services.venator = {
    requires = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
  };

  users = {
    users.venator = {
      isSystemUser = true;
      group = "venator";
    };
    groups.venator = { };
  };

  sops.secrets.venator-admin-psk = {
    sopsFile = ../../../../secrets/venator-admin-psk.sentinel.secret;
    format = "binary";
    owner = "venator";
    group = "venator";
    mode = "0440";
    reloadUnits = [ "venator.service" ];
  };

  sops.secrets.venator-pepper = {
    sopsFile = ../../../../secrets/venator-pepper.sentinel.secret;
    format = "binary";
    owner = "venator";
    group = "venator";
    mode = "0440";
    reloadUnits = [ "venator.service" ];
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/.well-known/matrix".proxyPass = "http://localhost:${toString port}";
    };

    ${federationDomain} = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString port}";
    };
  };
}
