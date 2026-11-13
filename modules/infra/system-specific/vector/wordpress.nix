{
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) genAttrs;

  domains = [
    "popkoorklankkleur.nl"
  ];

  ignoreTranslationUpdatesPlugin = pkgs.writeText "ignore-translation-updates.php" ''
    <?php
    /**
     * Plugin Name: Ignore WordPress Translation Updates
     * Description: Ignore language pack updates managed externally.
     */

    function ignore_translation_updates( $transient ) {
      if ( is_object( $transient ) && isset( $transient->translations ) ) {
        $transient->translations = array();
      }

      return $transient;
    }

    add_filter( 'site_transient_update_core', 'ignore_translation_updates' );
    add_filter( 'site_transient_update_plugins', 'ignore_translation_updates' );
    add_filter( 'site_transient_update_themes', 'ignore_translation_updates' );
  '';
in
{
  services.wordpress = {
    webserver = "nginx";
    sites = genAttrs domains (domain: {
      package = pkgs.wordpress.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/share/wordpress/wp-content/mu-plugins
          cp ${ignoreTranslationUpdatesPlugin} $out/share/wordpress/wp-content/mu-plugins/ignore-translation-updates.php
        '';
      });
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
          opengraph
          view-transitions
          wp-user-avatars
          # keep-sorted end
          ;
        inherit (pkgs.local) wp-oidc-roles;
      };
      themes = {
        inherit (pkgs.wordpressPackages.themes) twentytwentyfive;
      };
      languages =
        let
          inherit (pkgs.local.wordpressPackages.languages) nl;
        in
        [
          nl
        ];
    });
  };

  services.nginx.virtualHosts = genAttrs domains (domain: {
    enableACME = true;
    forceSSL = true;
    rateLimit.enable = false;
    enableHSTS = true;
    serverAliases = [ "www.${domain}" ];
    locations."/".proxyWebsockets = true;
  });

  infra.backup.jobs.state.paths = map (domain: "/var/lib/wordpress/${domain}") domains;
}
