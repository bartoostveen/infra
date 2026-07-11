{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib) mkForce getExe';

  forgeUrl =
    inputs.self.nixosConfigurations.bart-server.config.services.forgejo.settings.server.DOMAIN;
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
      endpoint = "https://${forgeUrl}/";
      gitAuthor = "Renovate <renovate@bartoostveen.nl>";
      platform = "forgejo";
      onboarding = true;
      requireConfig = "optional";

      autodiscover = true;
      autodiscoverFilter = [ "bart/*" ];

      prHourlyLimit = 50;
      lockFileMaintenance.enabled = true;
      minimumReleaseAge = "7 days";

      cacheTtlOverride.datasource-forgejo-tags = 0;

      packageRules = [
        {
          matchManagers = [ "github-actions" ];
          overrideDatasource = "forgejo-tags";
        }
        {
          matchManagers = [ "github-actions" ];
          matchPackageNames = [ "actions/setup-home" ];
          overrideDatasource = "forgejo-tags";
          automerge = true;
          minimumReleaseAge = "1 second";
        }
        {
          matchDatasources = [ "forgejo-tags" ];
          registryUrls = [ "https://${forgeUrl}" ];
        }
      ];
    };
    runtimePackages = with pkgs; [
      nix
      git
      gnupg
      nodejs
      bun
      pnpm
      go
      phpPackages.composer
      gradle
      openjdk25_headless
    ];
  };

  systemd.services.renovate.serviceConfig.BindReadOnlyPaths = [
    "${getExe' pkgs.bash "sh"}:/bin/sh"
    "${getExe' pkgs.coreutils "env"}:/usr/bin/env"
  ];

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
