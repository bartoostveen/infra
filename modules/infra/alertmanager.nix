{ config, wireguard, ... }:

let
  emailHost = "bartoostveen.nl";
  email = "alerts@${emailHost}";
in
{
  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = wireguard.primaryIpOf config.networking.hostName;

    configuration = {
      global = {
        smtp_from = "Alerting <${email}>";
        smtp_smarthost = "${emailHost}:465"; # for some reason only implicit TLS works
        smtp_auth_username = email;
        smtp_auth_password_file = config.sops.secrets.alertmanager-email-password.path;
      };

      receivers = [
        {
          name = "matrix";
          webhook_configs = [
            {
              url = "http://localhost:4051/!XEut2ilhrx5AFftWSym-qSzEW370UbEYfuxVfOWfY-A";
            }
          ];
        }
        {
          name = "email";
          email_configs = [
            {
              to = "root@bartoostveen.nl";
            }
          ];
        }
      ];

      # give me all destinations pls
      route = {
        receiver = (builtins.elemAt config.services.prometheus.alertmanager.configuration.receivers 0).name;
        routes = map (el: {
          receiver = el.name;
          continue = true;
        }) config.services.prometheus.alertmanager.configuration.receivers;
      };
    };
  };

  systemd.services.alertmanager = {
    requires = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
  };

  sops.secrets.alertmanager-email-password = {
    format = "binary";
    mode = "0600";

    sopsFile = ../../secrets/email-passwords/alertmanager.secret;
    restartUnits = [ "alertmanager.service" ];
    owner = "alertmanager";
    group = "alertmanager";
  };

  users.groups.alertmanager = { };
  users.users.alertmanager = {
    isSystemUser = true;
    group = "alertmanager";
  };
}
