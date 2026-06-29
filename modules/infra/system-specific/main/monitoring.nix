{
  pkgs,
  config,
  inputs,
  lib,
  wireguard,
  ...
}:

let
  grafanaVHost = "grafana.vitune.app";

  inherit (lib)
    # keep-sorted start
    attrNames
    concatMap
    filterAttrs
    mapAttrsToList
    optionals
    removeAttrs
    # keep-sorted end
    ;

  uptimeKumaMetricsPort = 15108;

  staticConfigsFor =
    {
      host,
      name,
      config' ? inputs.self.nixosConfigurations.${name}.config,
    }:

    let
      hostName = name;
    in
    (
      config'.services.prometheus.exporters
      |> filterAttrs (
        _: e:
        let
          evaluated = builtins.tryEval e;
        in
        evaluated.success && e ? enable && e.enable
      )
      |> attrNames
      |> map (jobName: {
        job_name = "${hostName}-${jobName}";
        static_configs = [
          {
            targets = [ "${host}:${toString config'.services.prometheus.exporters.${jobName}.port}" ];
          }
        ];
      })
    )
    ++ (optionals config'.services.telegraf.enable [
      {
        job_name = "${hostName}-telegraf";
        static_configs = [
          {
            targets = [ "${host}${config'.services.telegraf.extraConfig.outputs.prometheus_client.listen}" ];
          }
        ];
      }
    ])
    ++ (
      if config' ? infra && config'.infra ? extraScrapeConfigs then
        config'.infra.extraScrapeConfigs
        |> mapAttrsToList (
          name: value:
          (removeAttrs value [ "port" ])
          // {
            job_name = "${hostName}-${name}";
            static_configs = [
              {
                targets = [ "${host}:${toString value.port}" ];
              }
            ];
          }
        )
      else
        [ ]
    );
in
{
  imports = [
    inputs.srvos.nixosModules.mixins-telegraf
    inputs.srvos.nixosModules.roles-prometheus

    ./rules
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

    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          {
            targets =
              inputs.self.nixosConfigurations
              |> filterAttrs (_: c: c.config.services.prometheus.alertmanager.enable)
              |> mapAttrsToList (
                _: c:
                let
                  alertmanager = c.config.services.prometheus.alertmanager;
                in
                "${alertmanager.listenAddress}:${toString alertmanager.port}"
              );
          }
        ];
      }
    ];

    extraFlags = [
      "--web.external-url=https://prometheus.vitune.app/"
    ];

    globalConfig.scrape_interval = "15s";
    retentionTime = "180d";

    exporters = {
      systemd.enable = true;
      postgres.enable = true;
      node.enable = true;
    };

    ruleFiles = [
      (pkgs.writers.writeJSON "infra.json" config.infra.monitoring)
    ];

    scrapeConfigs = [
      {
        job_name = "elisaado_ooye";
        scheme = "https";
        static_configs = [
          { targets = [ "ooye.elisaado.com" ]; }
        ];
      }
    ]
    ++ concatMap (
      name:
      staticConfigsFor {
        inherit name;
        host = wireguard.primaryIpOf name;
      }
    ) (builtins.filter (n: inputs.self.nixosConfigurations ? "${n}") (attrNames wireguard.nodes));
  };

  services.nginx.virtualHosts.${config.infra.authentik.domain}.serverAliases = [
    "prometheus.vitune.app"
  ];

  infra.backup.jobs.state = {
    paths = [
      "/var/lib/${config.services.prometheus.stateDir}"
      config.services.grafana.dataDir
    ];
    exclude = [ "/var/lib/${config.services.prometheus.stateDir}/data/wal" ];
  };

  sops.secrets.grafana-secret = {
    format = "binary";
    mode = "0600";

    sopsFile = ../../../../secrets/grafana.bart-server.secret;
    restartUnits = [ "grafana.service" ];
    owner = "grafana";
    group = "grafana";
  };

  services.uptime-kuma = {
    enable = true;
    settings.HOST = "0.0.0.0";
  };

  services.anubis.instances.uptime-kuma.settings = {
    BIND = "/run/anubis/anubis-uptime-kuma/anubis-uptime-kuma.sock";
    TARGET = "http://${config.services.uptime-kuma.settings.HOST}:${toString config.services.uptime-kuma.settings.PORT}";
    METRICS_BIND = "0.0.0.0:${toString uptimeKumaMetricsPort}";
    METRICS_BIND_NETWORK = "tcp";
  };

  infra.extraScrapeConfigs.uptime-kuma-anubis.port = uptimeKumaMetricsPort;

  services.nginx.virtualHosts."uptime.bartoostveen.nl" = {
    enableACME = true;
    forceSSL = true;
    serverAliases = [ "status.bartoostveen.nl" ];
    locations."/" = {
      proxyPass = "http://unix://${config.services.anubis.instances.uptime-kuma.settings.BIND}";
      proxyWebsockets = true;
    };
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

  infra.extraScrapeConfigs.loki.port = config.services.loki.configuration.server.http_listen_port;
}
