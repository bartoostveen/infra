{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkForce
    makeSearchPathOutput
    ;
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
      dockerImage = "nixos/nix";
      dockerVolumes = [
        "/var/lib/gitlab-runner/cache:/cache"
        "/nix/store:/nix/store:ro"
        "/nix/var/nix/db:/nix/var/nix/db:ro"
        "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket"
      ];
      environmentVariables = {
        NIX_REMOTE = "daemon";
        PATH =
          (makeSearchPathOutput "bin" "bin" [
            pkgs.gnugrep
            pkgs.coreutils
            pkgs.nix
            pkgs.openssh
            pkgs.bash
            pkgs.git
          ])
          + ":/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/local/sbin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
      };
      dockerPrivileged = true;
      dockerPullPolicy = "if-not-present";
      requestConcurrency = paralellism;
    };
  };
  services.gitlab-runner.clear-docker-cache.enable = true;

  systemd.services.gitlab-runner = {
    requires = [
      "sops-install-secrets.service"
      "podman.socket"
    ];
    after = [
      "sops-install-secrets.service"
      "podman.socket"
    ];
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
