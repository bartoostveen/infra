let
  port = 8449;
  domain = "venator.omeduostuurcentenneef.nl";
  federationDomain = "server.${domain}";
in
{
  imports = [ ../../venator.nix ];

  services.venator = {
    enable = true;
    configurePostgres = true;
    settings = {
      registration.enabled = false;
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
