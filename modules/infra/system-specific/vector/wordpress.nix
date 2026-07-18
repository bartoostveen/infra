{
  pkgs,
  config,
  ...
}:

let
  domain = "popkoorklankkleur.nl";

  nl = pkgs.local.wordpressPackages.lang {
    lang = "nl_NL";
    inherit (config.services.wordpress.sites.${domain}.package) version;
    hash = "sha256-T9A5hSqlGD+yuklkxmbSP7T2Xjj8bfsIS4kqbMkrjQk=";
  };
in
{
  services.wordpress = {
    webserver = "nginx";
    sites.${domain} = {
      settings = {
        WP_DEFAULT_THEME = "twentytwentyfive";
        WP_SITEURL = "https://${domain}";
        WP_HOME = "https://${domain}";
        WP_DEBUG = true;
        WP_DEBUG_DISPLAY = false;

        WPLANG = "nl_NL";
        FORCE_SSL_ADMIN = true;
        AUTOMATIC_UPDATER_DISABLED = true;
      };
      plugins = {
        inherit (pkgs.local.wordpressPackages.plugins)
          # keep-sorted start
          antispam-bee
          contact-form-7
          generic-oidc
          gutenberg
          gutenberg-carousel
          indexnow
          modify-profile-fields
          view-transitions
          # keep-sorted end
          ;
        inherit (pkgs.wordpressPackages.plugins)
          # keep-sorted start
          opengraph
          wp-user-avatars
          # keep-sorted end
          ;
        inherit (pkgs.local) wp-oidc-roles;
      };
      themes = {
        inherit (pkgs.wordpressPackages.themes) twentytwentyfive;
      };
      languages = [ nl ];
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    rateLimit.enable = false;
    enableHSTS = true;
    serverAliases = [ "www.${domain}" ];
    locations."/".proxyWebsockets = true;
  };

  infra.backup.jobs.state.paths = [ "/var/lib/wordpress/${domain}" ];
}
