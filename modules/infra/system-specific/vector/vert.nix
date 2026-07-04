{
  inputs,
  config,
  lib,
  ...
}:

let
  anubisMetricsPort = 15888;

  inherit (lib) genAttrs;
in
{
  imports = [ inputs.vert-nix.nixosModules.default ];

  services.vert = {
    enable = true;
    environmentFile = config.sops.secrets.vert-env.path;
    hostName = "vert.vitune.app";
    nginx = {
      enable = true;
      enableACME = true;
      forceSSL = true;
    };
  };

  services.nginx.virtualHosts.${config.services.vert.hostName} = {
    rateLimit.burst = 100;
    connectionLimit.connections = 50;
    extraConfig = ''
      add_header Access-Control-Allow-Credentials true;
    '';
    locations = {
      "/.within.website/" = {
        proxyPass = "http://unix://${config.services.anubis.instances.vert.settings.BIND}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_request_buffering off;
          proxy_buffers 32 8k;
          proxy_buffer_size 16k;
          proxy_busy_buffers_size 24k;
          proxy_pass_request_body off;
          proxy_set_header content-length "";
          auth_request off;
        '';
      };
      "@redirectToAnubis" = {
        return = "307 /.within.website/?redir=$scheme://$host$request_uri";
        extraConfig = ''
          auth_request off;
        '';
      };
    }
    // genAttrs [ "/" "/daemon/" ] (_: {
      extraConfig = ''
        auth_request /.within.website/x/cmd/anubis/api/check;
        error_page 401 = @redirectToAnubis;
      '';
    });
  };

  services.anubis.instances.vert = {
    policy.settings.status_codes = {
      CHALLENGE = 200;
      DENY = 403;
    };
    settings = {
      BIND = "/run/anubis/anubis-vert/anubis-vert.sock";
      TARGET = " ";
      METRICS_BIND = "0.0.0.0:${toString anubisMetricsPort}";
      METRICS_BIND_NETWORK = "tcp";
    };
  };

  infra.extraScrapeConfigs.vert-anubis.port = anubisMetricsPort;
  infra.autokuma.instances.local = {
    tags.vertd = {
      name = "vertd";
      color = "#ff0000";
    };
    monitors.vertd = {
      type = "json-query";
      name = "${config.services.vert.hostName} vertd";
      description = "Vertd success test for ${config.services.vert.hostName} Managed by AutoKuma";
      url = "https://${config.services.vert.hostName}/daemon/api/version";
      notification_name_list = [ "autokuma-matrix" ];
      tag_names = [
        {
          name = "autokuma";
          value = "Matrix";
        }
        {
          name = "vertd";
          value = config.services.vert.hostName;
        }
      ];
      json_path = "type";
      json_path_operator = "==";
      expected_value = "success";
      timeout = 10;
      interval = 20;
      retry_interval = 20;
    };
  };

  systemd.services.vert.serviceConfig = {
    MemoryHigh = "2G";
    CPUQuota = "200%";
  };

  sops.secrets.vert-env = {
    sopsFile = ../../../../secrets/vert.env.vector.secret;
    owner = "vertd";
    group = "vertd";
    mode = "0440";
    restartUnits = [ "vertd.service" ];
    format = "binary";
  };
}
