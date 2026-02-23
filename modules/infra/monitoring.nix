{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:

let
  kumaVHost = "uptime.bartoostveen.nl";
  grafanaVHost = "grafana.vitune.app";
in
{
  imports = [
    inputs.srvos.nixosModules.mixins-telegraf
    inputs.srvos.nixosModules.roles-prometheus
  ];

  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = grafanaVHost;
        root_url = "https://${grafanaVHost}";
        protocol = "socket";
      };
      security.secret_key = "$__file{${config.sops.secrets.grafana-secret.path}}";
    };
  };

  services.nginx.virtualHosts.${grafanaVHost} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://unix:${config.services.grafana.settings.server.socket}";
      proxyWebsockets = true;
    };
  };

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "grafana" ];

  services.prometheus = {
    enable = true;

    listenAddress = "127.0.0.1";
    port = 7070;

    alertmanager = {
      enable = true;
      listenAddress = "127.0.0.1";
      configuration =
        let
          receiver = "admin";
        in
        {
          global =
            let
              email = "alerts@${config.mailserver.fqdn}";
            in
            {
              smtp_from = "Alerting <${email}>";
              smtp_smarthost = "${config.mailserver.fqdn}:465";
              smtp_auth_username = email;
              smtp_auth_password_file = config.sops.secrets.alertmanager-email-password.path;
            };
          receivers = [
            {
              name = receiver;
              email_configs = [
                {
                  to = "root@bartoostveen.nl";
                }
              ];
              discord_configs = [
                {
                  webhook_url_file = config.sops.secrets.alertmanager-discord-webhook.path;
                }
              ];
            }
          ];
          route = { inherit receiver; };
        };
    };

    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          {
            targets = [
              "${config.services.prometheus.alertmanager.listenAddress}:${toString config.services.prometheus.alertmanager.port}"
            ];
          }
        ];
      }
    ];

    extraFlags = [
      "--web.external-url=https://prometheus.vitune.app/"
    ];

    globalConfig.scrape_interval = "15s";
    retentionTime = "180d";

    exporters.nginx.enable = true;
    exporters.systemd.enable = true;
    exporters.postgres.enable = true;
    exporters.node.enable = true;

    ruleFiles = [
      (pkgs.writeText "up.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "up";
              rules = [
                {
                  alert = "NotUp";
                  expr = ''
                    up == 0
                  '';
                  for = "1m";
                  labels.severity = "warning";
                  annotations.summary = "scrape job {{ $labels.job }} is failing on {{ $labels.instance }}";
                }
              ];
            }
          ];
        }
      ))
    ];

    scrapeConfigs = [
      {
        job_name = "nginx";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.nginx.port}" ];
          }
        ];
      }
      {
        job_name = "systemd";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.systemd.port}" ];
          }
        ];
      }
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
      {
        job_name = "postgres";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.postgres.port}" ];
          }
        ];
      }
      {
        job_name = "telegraf";
        static_configs = [
          {
            targets = [ "localhost${config.services.telegraf.extraConfig.outputs.prometheus_client.listen}" ];
          }
        ];
      }
      {
        job_name = "uptime-kuma-anubis";
        static_configs = [
          {
            targets = [ config.services.anubis.instances.uptime-kuma.settings.METRICS_BIND ];
          }
        ];
      }
    ];
  };

  services.nginx.virtualHosts."prometheus.vitune.app" = {
    enableACME = true;
    forceSSL = true;
    listenAddresses = [ "100.64.0.2" ];
    locations."/" = {
      proxyPass = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
    };
  };

  sops.secrets.alertmanager-discord-webhook = {
    format = "binary";
    mode = "0600";

    sopsFile = ../../secrets/alertmanager-discord-webhook.secret;
    restartUnits = [ "alertmanager.service" ];
    owner = "alertmanager";
    group = "alertmanager";
  };

  sops.secrets.grafana-secret = {
    format = "binary";
    mode = "0600";

    sopsFile = ../../secrets/grafana.secret;
    restartUnits = [ "grafana.service" ];
    owner = "grafana";
    group = "grafana";
  };

  services.uptime-kuma.enable = true;

  services.anubis.instances.uptime-kuma = {
    botPolicy = {
      bots = [
        {
          name = "telegram";
          user_agent_regex = "TelegramBot (like TwitterBot)";
          action = "ALLOW";
        }
        {
          name = "tailscale";
          remote_addresses = [ "100.64.0.0/16" ];
          action = "ALLOW";
        }
      ];
    };

    settings = {
      BIND = "/run/anubis/anubis-uptime-kuma/anubis-uptime-kuma.sock";
      TARGET = "http://${config.services.uptime-kuma.settings.HOST}:${toString config.services.uptime-kuma.settings.PORT}";
      METRICS_BIND = "127.0.0.1:15108"; # Prometheus can't scrape Unix sockets
      METRICS_BIND_NETWORK = "tcp";
    };
  };

  services.nginx.virtualHosts.${kumaVHost} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://unix://${config.services.anubis.instances.uptime-kuma.settings.BIND}";
      proxyWebsockets = true;
    };
  };

  infra.autokuma = {
    # TODO: Docker etc.
    enable = lib.mkDefault true;
    defaultEnvFile = config.sops.secrets.autokuma-env.path;
    defaultSettings = {
      kuma = {
        url = config.services.anubis.instances.uptime-kuma.settings.TARGET;
        username = "adm";
      };
      tag_name = "Managed by AutoKuma";
      tag_color = "#ea2121";
    };
    instances.local = {
      tags.nginx = {
        name = "nginx @ ${config.networking.hostName}";
        color = "#17964a";
      };
      monitors =
        lib.genAttrs
          (builtins.filter (kumaVHost: kumaVHost != "localhost") (
            lib.attrNames config.services.nginx.virtualHosts
          ))
          (kumaVHost: {
            type = "http";
            name = kumaVHost;
            description = "nginx Managed by AutoKuma @ ${config.networking.hostName}";
            expiry_notification = true;
            url = "https://${kumaVHost}";
            accepted_statuscodes = [ "200-399" ];
            tag_names = [
              {
                name = "nginx";
                value = kumaVHost;
              }
            ];
          });
    };
  };

  sops.secrets.autokuma-env = {
    owner = "root";
    group = "root";
    mode = "0600";

    sopsFile = ../../secrets/autokuma.env.secret;
    format = "binary";
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = 3100;
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/tmp/loki";
      };
      schema_config.configs = [
        {
          from = "2025-09-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config.filesystem.directory = "/tmp/loki/chunks";
    };
  };

  services.alloy = {
    enable = true;
    extraFlags = [ "--disable-reporting" ];
  };
  environment.etc."alloy/config.alloy".text = ''
    loki.source.journal "journal" {
      max_age       = "24h0m0s"
      forward_to    = [loki.write.default.receiver]
      labels        = {
        host = "${config.networking.hostName}",
        job  = "systemd_journal",
      }
      relabel_rules = loki.relabel.journal.rules
    }

    loki.relabel "journal" {
      forward_to = []
      
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
    }

    loki.write "default" {
      endpoint {
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push"
      }
      external_labels = {}
    }
  '';
}
