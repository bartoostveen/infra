{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib) isString;

  max = config.nix.settings.max-jobs;
  maxJobs = if isString max then 4 else max;
in
{
  imports = [
    ./common.nix
    inputs.hydra.nixosModules.builder
  ];

  services.hydra-queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "https://queue.hydra.bartoostveen.nl";
    authorizationFile = config.sops.secrets.queue-runner-token.path;
    inherit maxJobs;
    useSubstitutes = true;
    supportedFeatures = config.nix.settings.system-features;
  };

  sops.secrets.queue-runner-token = {
    sopsFile = ../../../secrets/hydra/${config.networking.hostName}-queue-runner-token.secret;
    format = "binary";
    owner = "hydra-queue-builder";
    group = "hydra";
    mode = "0400";
    restartUnits = [ "hydra-queue-builder-dev.service" ];
  };
}
