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

  wildcardVHosts = [
    domain
    preview-domain
  ];

  vHosts = wildcardVHosts ++ [
    "search.boostveen.nl"
    "test.search.bartoostveen.nl"
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

  security.acme.certs = genAttrs wildcardVHosts (h: {
    domain = "*.${h}";
    extraDomainNames = [ h ];
    dnsProvider = "cloudflare";
    environmentFile = config.sops.secrets.acme-env.path;
    group = "nginx";
  });

  services.nginx.virtualHosts = genAttrs' vHosts (
    h:

    let
      isWildcard = builtins.elem h wildcardVHosts;
    in
    nameValuePair (if isWildcard then "*.${h}" else h) {
      forceSSL = true;
      useACMEHost = if isWildcard then h else null;
      enableACME = !isWildcard;
      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
        extraConfig = ''
          ssi on;
          proxy_pass_header Server;
          proxy_set_header Accept-Encoding "";
          proxy_intercept_errors on;
        '';
      };
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
