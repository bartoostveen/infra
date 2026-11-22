{
  pkgs,
  smallPkgs,
  lib,
  continuwuityPkgs,
  config,
  inputs,
  flakeRoot,
  ...
}:

let
  inherit (lib) range genAttrs' nameValuePair;

  fqdn = "bartoostveen.nl";
  cinnies = range 0 9;

  sableDomain = "sable.${fqdn}";
in
{
  imports = [
    ../../matrix
    inputs.bart-packages.nixosModules.sable
  ];

  infra.matrix = {
    enable = true;
    package = continuwuityPkgs.matrix-continuwuity;
    enableBackups = true;
    inherit fqdn;
    domain = "matrix.${fqdn}";
    livekit = {
      enable = true;
      domain = "matrix-rtc.${fqdn}";
    };
    call = {
      enable = true;
      package = smallPkgs.element-call;
      domain = "call.${fqdn}";
    };
    element = {
      enable = true;
      domain = "element.${fqdn}";
    };
    discord.enable = false;
    signal.enable = true;
    telegram.enable = true;
    cinny = {
      enable = true;
      package = pkgs.local.sable.override {
        conf = {
          homeserverList = [
            fqdn
            "elisaado.com"
            "utwente.io"
            "matrix.org"
            "inter-actief.net"
          ];
          defaultHomeserver = 0;
          allowCustomHomeservers = true;
          featuredCommunities = { };
          settingsDefaults = {
            alwaysShowCallButton = true;
            badgeCountDMsOnly = true;
            bundledPreview = false;
            clearNotificationsOnRead = true;
            clientPreviewYoutube = true;
            clientUrlPreview = false;
            closeFoldersByDefault = true;
            composerToolbarOpen = false;
            customDMCards = true;
            developerTools = true;
            emojiSuggestThreshold = 2;
            encClientUrlPreview = false;
            encUrlPreview = false;
            faviconForMentionsOnly = false;
            hideActivity = false;
            hideMembershipEvents = false;
            hideMembershipInReadOnly = false;
            hideNickAvatarEvents = false;
            hideReads = false;
            highlightMentions = true;
            hour24Clock = true;
            incomingInlineImagesDefaultHeight = 32;
            incomingInlineImagesMaxHeight = 64;
            isNotificationSounds = false;
            legacyUsernameColor = false;
            linkPreviewImageMaxHeight = 640;
            showHiddenEvents = true;
            showTombstoneEvents = true;
            hiddenEventEdits = false;
            hiddenEventRedactionTimeline = true;
            hiddenEventReactions = false;
            hiddenEventReactionTombstone = false;
            hiddenEventReactionRedactionTimeline = false;
            hiddenEventOther = true;
            showMessageContentInEncryptedNotifications = false;
            showMessageContentInNotifications = true;
            showPingCounts = true;
            showPronouns = true;
            showUnreadCounts = true;
            themeRemoteCatalogEnabled = true;
            themeRemoteDarkFullUrl = "https://raw.githubusercontent.com/SableClient/themes/main/themes/cinny-dark.sable.css";
            themeRemoteDarkKind = "dark";
            themeRemoteFavorites = [
              {
                basename = "cinny-dark";
                displayName = "Cinny Dark";
                fullUrl = "https://raw.githubusercontent.com/SableClient/themes/main/themes/cinny-dark.sable.css";
                kind = "dark";
                pinned = false;
              }
            ];
            urlPreview = true;
            useInAppNotifications = true;
          };
          gifs = {
            provider = "klipy";
            proxyUrl = "gifs.sable.moe";
            klipyApiKey = "IfeIBlDMvq0av2BcKPDuxwRqbnYRbS90yNqFHEkK2Ja207tkR5nssh3NIlJRCr76";
          };
        };
      };
      domains = map (n: "cinny${toString n}.${fqdn}") cinnies;
    };
  };

  services.sable = {
    enable = true;
    package = pkgs.local.sable-next-server;
    frontendPackage = pkgs.local.sable-next-server-frontend;
    environmentFile = config.sops.secrets.sable-server-env.path;
    settings = {
      public_url = "https://${sableDomain}";
      client_ip_source = "RightmostXForwardedFor";
      username = "bart";
    };
  };

  sops.secrets.sable-server-env = {
    sopsFile = /${flakeRoot}/secrets/sable-server.env.sentinel.secret;
    format = "binary";
    restartUnits = [ "sable.service" ];
  };

  services.nginx.virtualHosts =
    (genAttrs' cinnies (
      n:
      nameValuePair "cinny${toString n}.${fqdn}" {
        serverAliases = [ "sable${toString n}.${fqdn}" ];
      }
    ))
    // {
      "sable.bartoostveen.nl" = {
        enableACME = true;
        forceSSL = true;
        rateLimit.burst = 1000;
        connectionLimit.connections = 200;
        locations."/" = {
          proxyPass = "http://${config.services.sable.settings.listen_addr}";
          proxyWebsockets = true;
        };
      };
      "sable-next.bartoostveen.nl" = {
        enableACME = true;
        forceSSL = true;
        rateLimit.burst = 1000;
        connectionLimit.connections = 200;
        root = pkgs.local.sable-next.override {
          conf = {
            homeserverList = [
              fqdn
              "elisaado.com"
              "utwente.io"
              "matrix.org"
              "inter-actief.net"
            ];
            defaultHomeserver = 0;
            allowCustomHomeservers = true;
            gifs = {
              provider = "klipy";
              proxyUrl = "gifs.sable.moe";
              klipyApiKey = "IfeIBlDMvq0av2BcKPDuxwRqbnYRbS90yNqFHEkK2Ja207tkR5nssh3NIlJRCr76";
            };
          };
        };
        locations = {
          "/".extraConfig = ''
            try_files $uri $uri.html $uri/index.html /index.html;
          '';
          "/_app/immutable/".extraConfig = ''
            add_header Cache-Control "public, max-age=31536000, immutable" always;
            try_files $uri =404;
          '';
          "= /manifest.webmanifest".extraConfig = ''
            default_type application/manifest+json;
          '';
        }
        // genAttrs' [ "index.html" "config.json" ] (
          name:
          nameValuePair "= /${name}" {
            extraConfig = ''
              add_header Cache-Control "no-cache" always;
            '';
          }
        );
      };
    };
}
