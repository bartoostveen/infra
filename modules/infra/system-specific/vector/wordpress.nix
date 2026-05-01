{ pkgs, config, ... }:

let
  domain = "popkoorklankkleur.nl";
  wordpressPackages = pkgs.callPackage ./wordpressPackages.nix { };

  nl = wordpressPackages.lang.nl config.services.wordpress.sites.${domain}.package.version;
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
        inherit (wordpressPackages.plugins)
          # keep-sorted start
          contact-form-7
          generic-oidc
          gutenberg
          gutenberg-carousel
          modify-profile-fields
          view-transitions
          # keep-sorted end
          ;
        inherit (pkgs.wordpressPackages.plugins)
          # keep-sorted start
          antispam-bee
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
      package = pkgs.wordpress_6_9;
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    enableRateLimit = false;
    enableHSTS = true;
    serverAliases = [ "www.${domain}" ];
    locations."/".proxyWebsockets = true;
  };

  infra.backup.jobs.state.paths = [ "/var/lib/wordpress/${domain}" ];
}
