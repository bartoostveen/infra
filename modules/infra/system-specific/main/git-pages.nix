{ config, lib, ... }:

let
  inherit (lib)
    genAttrs
    genAttrs'
    nameValuePair
    ;

  port = 62012;
  metricsPort = port + 1;

  domain = "pages.bartoostveen.nl";
  preview-domain = "preview.bartoostveen.nl";

  vHosts = [
    domain
    preview-domain
  ];
in
{
  imports = [ ../../git-pages.nix ];

  services.git-pages = {
    enable = true;
    settings = {
      server = {
        pages = "tcp/127.0.0.1:${toString port}";
        metrics = "tcp/0.0.0.0:${toString metricsPort}";
      };
      wildcard = [
        {
          authorization = "forgejo";
          clone-url = "https://${config.services.forgejo.settings.server.DOMAIN}/<user>/<project>.git";
          inherit domain; # preview-domain; # Unstable
          index-repo = "pages";
          index-repo-branch = "main";
          # max-preview-lifetime = "7d"; # Unstable
        }
      ];
    };
  };

  security.acme.certs = genAttrs vHosts (h: {
    domain = "*.${h}";
    extraDomainNames = [ h ];
    dnsProvider = "cloudflare";
    environmentFile = config.sops.secrets.acme-env.path;
    group = "nginx";
  });

  services.nginx.virtualHosts = genAttrs' vHosts (
    h:
    nameValuePair "*.${h}" {
      forceSSL = true;
      useACMEHost = h;
      locations."/".proxyPass = "http://localhost:${toString port}";
    }
  );

  infra.extraScrapeConfigs.git-pages.port = metricsPort;

  sops.secrets.acme-env = {
    sopsFile = ../../../../secrets/lego.env.bart-server.secret;
    format = "binary";
    owner = "acme";
    group = "acme";
    mode = "0770";
    restartUnits = map (d: "acme-${d}.service") vHosts;
  };
}
