{ lib, config, ... }:

let
  inherit (lib)
    mkIf
    genAttrs
    optionalString
    ;

  cfg = config.infra.matrix;

  location = {
    root = "${cfg.cinny.package}";
    extraConfig = optionalString (!cfg.cinny.package.conf.hashRouter.enabled) ''
      rewrite ^/config.json$ /config.json break;
      rewrite ^/manifest.json$ /manifest.json break;

      rewrite ^/sw.js$ /sw.js break;
      rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;

      rewrite ^/public/(.*)$ /public/$1 break;
      rewrite ^/assets/(.*)$ /assets/$1 break;

      rewrite ^(.+)$ /index.html break;
    '';
  };

  cinnies = genAttrs cfg.cinny.domains (_: {
    enableACME = true;
    forceSSL = true;
    locations."/" = location;
  });
in
{
  config = mkIf (cfg.enable && cfg.cinny.enable) {
    services.nginx.virtualHosts = {
      ${cfg.domain} = mkIf cfg.cinny.replaceContinuwuity {
        locations."/" = location;
      };
    }
    // cinnies;
  };
}
