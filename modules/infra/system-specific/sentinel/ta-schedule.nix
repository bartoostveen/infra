{
  config,
  pkgs,
  inputs,
  ...
}:

let
  settings = config.services.ta-schedule.settings;
in
{
  imports = [ inputs.ta-schedule.nixosModules.default ];

  services.ta-schedule = {
    enable = true;
    package = inputs.ta-schedule.packages.${pkgs.stdenv.hostPlatform.system}.ta-schedule;
    inputFile = config.sops.secrets.ta-schedule.path;
    settings = {
      hostname = "ta.bartoostveen.nl";
      port = 6146;
      listen = "127.0.0.1";
      timezone = "Europe/Amsterdam";
      prefix = "M2";
    };
    environmentFile = config.sops.secrets.ta-schedule-env.path;
  };

  services.nginx.virtualHosts.${settings.hostname} = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://${settings.listen}:${toString settings.port}";
  };

  sops.secrets.ta-schedule = {
    sopsFile = ../../../../secrets/ta-schedule.xlsx.sentinel.secret;
    mode = "0440";
    owner = "ta-schedule";
    group = "ta-schedule";
    format = "binary";
    # TODO: add reload functionality
    restartUnits = [ "ta-schedule.service" ];
  };

  sops.secrets.ta-schedule-env = {
    sopsFile = ../../../../secrets/ta-schedule.env.sentinel.secret;
    mode = "0440";
    format = "binary";
    restartUnits = [ "ta-schedule.service" ];
  };

  users.users.ta-schedule = {
    isSystemUser = true;
    group = "ta-schedule";
  };
  users.groups.ta-schedule = { };
}
