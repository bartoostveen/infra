{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

let
  inherit (lib) mkIf;
in
{
  imports = [ inputs.bart-packages.nixosModules.alertmanager-matrix ];

  config = mkIf (config.infra.matrix.enable && config.infra.matrix.alertmanager.enable) {
    services.alertmanager-matrix = {
      enable = true;
      package = pkgs.local.alertmanager-matrix;
      useLocalAlertmanager = true;
      environmentFile = config.sops.secrets.alertmanager-matrix-env.path;
      settings = {
        message.type = "m.text";
        log.level = "debug";
        show.labels = true;
        homeserver = "https://${config.infra.matrix.domain}";
        user.id = "@alerts:bartoostveen.nl";
      };
    };

    systemd.services.alertmanager-matrix = {
      after = [
        "continuwuity.service"
        "sops-install-secrets.service"
      ];
      requires = [ "sops-install-secrets.service" ];
    };

    sops.secrets.alertmanager-matrix-env = {
      sopsFile = ../../../secrets/matrix/alertmanager-matrix.env.bart-server.secret;
      owner = "alertmanager-matrix";
      group = "alertmanager-matrix";
      format = "binary";
      mode = "440";
      restartUnits = [ "alertmanager-matrix.service" ];
    };

    users.users.alertmanager-matrix = {
      isSystemUser = true;
      group = "alertmanager-matrix";
    };
    users.groups.alertmanager-matrix = { };
  };
}
