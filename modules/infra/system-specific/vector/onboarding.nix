{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  redisSocket = "/run/redis-onboarding/redis.sock";

  emailUser = "onboarding";
  cfg = {
    authentik.base_url = "https://${config.infra.authentik.domain}";
    redis.host = "unix://${redisSocket}";
    smtp = {
      from = "Popkoor KlankKleur Onboarding <${emailUser}@${config.mailserver.systemDomain}>";
      host = config.mailserver.fqdn;
      port = 25;
      user = "${emailUser}@${config.mailserver.systemDomain}";
    };
    port = 64617;
  };
  configFormat = pkgs.formats.yaml { };
  configFile = configFormat.generate "onboarding-config.yaml" cfg;

  inherit (lib) getExe;

  pkg = inputs.onboarding.packages.${pkgs.stdenv.system}.default;
in
{
  systemd.services.authentik-onboarding =
    let
      dependencies = [
        "redis-onboarding.service"
        "authentik.service"
        "authentik-worker.service"
      ];
    in
    {
      description = "Authentik Onboarding service";
      wantedBy = [ "multi-user.target" ];
      requires = dependencies;
      wants = dependencies;
      after = dependencies;
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = "30s";
        UMask = "0027";
        EnvironmentFile = config.sops.secrets.onboarding-env.path;
        ExecStart = "${getExe pkg} -c ${configFile}";
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        ProtectKernelLogs = true;
        ProtectKernelTunables = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        PrivateUsers = true;
        ProtectClock = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = "@system-service";
      };
    };

  users.users.authentik-onboarding = {
    isSystemUser = true;
    group = "authentik-onboarding";
    description = "authentik-onboarding service user";
  };
  users.groups.authentik-onboarding = { };

  services.redis.servers.onboarding = {
    enable = true;
    user = "authentik-onboarding";
    unixSocket = redisSocket;
    unixSocketPerm = 770;
  };

  infra.extraScrapeConfigs.onboarding = {
    port = cfg.port;
    metrics_path = "/metrics";
  };

  # Proxy provider handles this
  services.nginx.virtualHosts.${config.infra.authentik.domain}.serverAliases = [
    "onboarding.${config.infra.authentik.domain}"
  ];

  sops.secrets.onboarding-env = {
    sopsFile = ../../../../secrets/onboarding.env.vector.secret;
    format = "binary";
    restartUnits = [ "authentik-onboarding.service" ];
  };
}
