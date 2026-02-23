{ config, pkgs, ... }:

let
  domain = "maubot.bartoostveen.nl";
in
{
  services.maubot = {
    enable = true;
    configMutable = false;
    pythonPackages = with pkgs.python3Packages; [ semver ];
    plugins = with config.services.maubot.package.plugins; [
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
      (idonthavespotify.overrideAttrs (finalAttrs: {
        version = "1.1.2";

        src = pkgs.fetchFromGitHub {
          owner = "HarHarLinks";
          repo = "maubot-idonthavespotify";
          tag = "v${finalAttrs.version}";
          hash = "sha256-gaucaS6v9lm9wTYy8fPDogT0KWKEgHhWR+rVsypp51k=";
        };

        preInstall = ''
          mv de.sosnowkadub.idonthavespotify-v1.1.2.mbp $pluginName
        '';
      }))
      join
      karma
      media
      reactbot
      reminder
      rss
      rss
      rsvc
      sed
      tex
      urlpreview
      wolframalpha
    ];
    settings = {
      server.hostname = "127.0.0.1";
      server.public_url = "https://${domain}";
      homeservers.default.url = "https://matrix.bartoostveen.nl";
      admins.bart = "$2b$15$uDScMFzqQJSOfMpveaN.W.vS7x9yNPd4boS4nFZrxqBN6bqZ7cMim";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass =
      "http://${config.services.maubot.settings.server.hostname}:${toString config.services.maubot.settings.server.port}";
  };
}
