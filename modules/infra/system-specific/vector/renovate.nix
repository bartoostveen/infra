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
    credentials.RENOVATE_TOKEN = config.sops.secrets.renovate-access-token.path;
    environment.LOG_LEVEL = "debug";
    settings = {
      endpoint = "https://git.bartoostveen.nl/";
      gitAuthor = "Renovate <renovate@bartoostveen.nl>";
      platform = "gitea";
      autodiscover = true;
      onboarding = true;
      requireConfig = "optional";
    };
    runtimePackages = with pkgs; [
      nix
      git
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
    sopsFile = ../../../../secrets/renovate-access-token.secret;
    restartUnits = [ "renovate.service" ];
  };
}
