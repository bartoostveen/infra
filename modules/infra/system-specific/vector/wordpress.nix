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
in
{
  services.wordpress = {
    webserver = "nginx";
    sites = genAttrs domains (domain: {
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
          # keep-sorted end
          ;
        inherit (pkgs.wordpressPackages.plugins)
          # keep-sorted start
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
          (nl.override {
            # TODO: remove
            hash = "sha256-TliAHBbYfNvM55lftkjXT7k/GsTD2EF9mxX94/m138w=";
          })
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
