{
  config,
  pkgs,
  ...
}:

let
  domain = "maubot.bartoostveen.nl";

  inherit (config.services.maubot.package) plugins;

  sed = plugins.sed.overrideAttrs {
    src = pkgs.fetchFromGitHub {
      owner = "maubot";
      repo = "sed";
      rev = "44865efc916c41ddfdfccadf72a2d8372381d064";
      hash = "sha256-j1/vqJPnOWRDqiRVW947HgZW/HvsHli20+q0cP4mj7E=";
    };
  };

  forgejo = plugins.buildMaubotPlugin rec {
    pname = "vibb.me.forgebot";
    version = "0.1.7";

    src = pkgs.fetchFromCodeberg {
      owner = "palchrb";
      repo = "maubot_forgejo";
      tag = "v${version}";
      hash = "sha256-IP985g6cPR3YRyrIaDikj3VAodIZjuYCYrJPiZGEDVw=";
    };
  };
in
{
  imports = [
    ../../maubot-exporter.nix
  ];

  services.maubot = {
    enable = true;
    configMutable = false;
    pythonPackages = with pkgs.python3Packages; [ semver ];
    plugins = with plugins; [
      # keep-sorted start
      alertbot
      autoreply
      choose
      communitybot
      dice
      disruptor
      echo
      factorial
      forgejo
      github
      gitlab
      join
      karma
      media
      reactbot
      reminder
      rss
      rsvc
      sed
      tex
      urlpreview
      wolframalpha
      # keep-sorted end
    ];
    settings = {
      server = {
        hostname = "127.0.0.1";
        public_url = "https://${domain}";
      };
      homeservers.default.url = "https://matrix.bartoostveen.nl";
      admins.bart = "$2b$15$uDScMFzqQJSOfMpveaN.W.vS7x9yNPd4boS4nFZrxqBN6bqZ7cMim";
    };
  };

  services.maubot-exporter = {
    enable = true;
    port = 25614;
    settings = {
      MAUBOT_API_BASE = "https://${domain}";
      MAUBOT_USERNAME = "bart";
    };
    environmentFile = config.sops.secrets.maubot-exporter-env.path;
  };
  users.users.maubot-exporter = {
    isSystemUser = true;
    group = "maubot-exporter";
  };
  users.groups.maubot-exporter = { };

  infra.extraScrapeConfigs.maubot.port = config.services.maubot-exporter.port;

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.maubot.settings.server.hostname}:${toString config.services.maubot.settings.server.port}";
      proxyWebsockets = true;
    };
  };

  sops.secrets.maubot-exporter-env = {
    sopsFile = ../../../../secrets/maubot-exporter.env.bart-server.secret;
    owner = "maubot-exporter";
    group = "maubot-exporter";
    format = "binary";
    mode = "0440";
    restartUnits = [ "maubot-exporter.service" ];
  };
}
