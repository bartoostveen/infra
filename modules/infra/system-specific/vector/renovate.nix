{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkForce;
in
{
  services.renovate = {
    enable = true;
    schedule = "*:0/15"; # every 15 minutes
    validateSettings = mkForce true;
    credentials = {
      RENOVATE_TOKEN = config.sops.secrets.renovate-access-token.path;
      RENOVATE_GIT_PRIVATE_KEY = config.sops.secrets.renovate-gpg-private.path;
      RENOVATE_GITHUB_COM_TOKEN = config.sops.secrets.renovate-github-pat.path;
    };
    environment.LOG_LEVEL = "debug";
    settings = {
      endpoint = "https://git.bartoostveen.nl/";
      gitAuthor = "Renovate <renovate@bartoostveen.nl>";
      platform = "forgejo";
      onboarding = true;
      requireConfig = "optional";

      autodiscover = true;
      autodiscoverFilter = [ "bart/*" ];

      prHourlyLimit = 50;
      lockFileMaintenance.enabled = true;
      allowedUnsafeExecutions = [ "gradleWrapper" ];
      minimumReleaseAge = "7 days";
    };
    runtimePackages = with pkgs; [
      nix
      git
      gnupg
      nodejs
      bun
      pnpm
      go
      gradle
      openjdk25_headless
    ];
  };

  users.users.renovate = {
    isSystemUser = true;
    group = "renovate";
  };
  users.groups.renovate = { };

  sops.secrets.renovate-access-token = {
    format = "binary";
    owner = "renovate";
    group = "renovate";
    mode = "0400";
    sopsFile = ../../../../secrets/renovate/renovate-access-token.vector.secret;
    restartUnits = [ "renovate.service" ];
  };

  sops.secrets.renovate-gpg-private = {
    format = "binary";
    owner = "renovate";
    group = "renovate";
    mode = "0400";
    sopsFile = ../../../../secrets/renovate/renovate-gpg-private.vector.secret;
    restartUnits = [ "renovate.service" ];
  };

  sops.secrets.renovate-github-pat = {
    format = "binary";
    owner = "renovate";
    group = "renovate";
    mode = "0400";
    sopsFile = ../../../../secrets/renovate/renovate-github-pat.vector.secret;
    restartUnits = [ "renovate.service" ];
  };
}
