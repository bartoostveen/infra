{ config, lib, ... }:

let
  inherit (lib) mkForce;
  paralellism = 6;
in
{
  virtualisation.docker.enable = mkForce false;
  services.gitlab-runner = {
    enable = true;
    settings.concurrent = paralellism;
    services.docker = {
      registrationFlags = [
        "--cache-type=path"
        "--cache-path=gitlab-runner"
        "--cache-shared=true"
        "--limit=${toString paralellism}"
      ];
      authenticationTokenConfigFile = config.sops.secrets.gitlab-runner-env.path;
      dockerImage = "docker:stable";
      dockerVolumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/gitlab-runner/cache:/cache"
      ];
      dockerPrivileged = true;
      tagList = [ "docker" ];
      requestConcurrency = paralellism;
    };
  };
  services.gitlab-runner.clear-docker-cache.enable = true;

  systemd.services.gitlab-runner = {
    requires = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
  };

  sops.secrets.gitlab-runner-env = {
    sopsFile = ../secrets/gitlab-runner.env.bart-pc.secret;
    mode = "0440";
    owner = "gitlab-runner";
    group = "gitlab-runner";
    format = "binary";
    restartUnits = [ "gitlab-runner.service" ];
  };

  users.users.gitlab-runner = {
    isSystemUser = true;
    group = "gitlab-runner";
  };
  users.groups.gitlab-runner = { };
}
