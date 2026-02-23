{
  config,
  pkgs,
  inputs,
  ...
}:

let
  domain = "maubot.bartoostveen.nl";

  spotify =
    let
      version = "1.1.2";
    in
    config.services.maubot.package.plugins.idonthavespotify.overrideAttrs {
      inherit version;
      src = inputs.maubot-spotify;
      preInstall = "mv de.sosnowkadub.idonthavespotify-v${version}.mbp $pluginName";
    };

  sed = config.services.maubot.package.plugins.sed.overrideAttrs {
    src = pkgs.fetchFromGitHub {
      owner = "maubot";
      repo = "sed";
      rev = "44865efc916c41ddfdfccadf72a2d8372381d064";
      hash = "sha256-j1/vqJPnOWRDqiRVW947HgZW/HvsHli20+q0cP4mj7E=";
    };
  };
in
{
  services.maubot = {
    enable = true;
    configMutable = false;
    pythonPackages = with pkgs.python3Packages; [ semver ];
    plugins = with config.services.maubot.package.plugins; [
      # keep-sorted start
      alertbot
      autoreply
      choose
      communitybot
      dice
      disruptor
      echo
      factorial
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
      spotify
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

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.maubot.settings.server.hostname}:${toString config.services.maubot.settings.server.port}";
      proxyWebsockets = true;
    };
  };
}
