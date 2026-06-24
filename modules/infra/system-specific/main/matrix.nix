{
  pkgs,
  smallPkgs,
  lib,
  continuwuityPkgs,
  ...
}:

let
  inherit (lib) range genAttrs' nameValuePair;

  fqdn = "bartoostveen.nl";
  cinnies = range 0 9;
in
{
  imports = [
    ../../matrix
  ];

  infra.matrix = {
    enable = true;
    package = continuwuityPkgs.matrix-continuwuity;
    inherit fqdn;
    domain = "matrix.${fqdn}";
    livekit = {
      enable = true;
      domain = "matrix-rtc.${fqdn}";
    };
    call = {
      enable = true;
      # TODO: remove
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
          hashRouter.enabled = true;
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
        };
      };
      domains = map (n: "cinny${toString n}.${fqdn}") cinnies;
    };
  };

  services.nginx.virtualHosts = genAttrs' cinnies (
    n:
    nameValuePair "cinny${toString n}.${fqdn}" {
      serverAliases = [ "sable${toString n}.${fqdn}" ];
    }
  );
}
