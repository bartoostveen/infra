{
  config,
  lib,
  pkgs,
  inputs,
  wireguard,
  ...
}:

let
  inherit (lib) mkDefault genAttrs attrNames;
in
{
  imports = [
    ./autokuma.nix
  ];

  infra.autokuma = {
    enable = mkDefault true;
    package = pkgs.local.autokuma;
    defaultEnvFile = config.sops.secrets.autokuma-env.path;
    defaultSettings = {
      kuma = {
        url = "http://${wireguard.primaryIpOf "bart-server"}:${toString inputs.self.nixosConfigurations.bart-server.config.services.uptime-kuma.settings.PORT}";
        username = "adm";
      };
      tag_name = "Managed by AutoKuma @ ${config.networking.fqdn}";
      tag_color = "#ea2121";
    };
    instances.local = {
      additionalMonitorFiles = [ config.sops.secrets.autokuma-matrix.path ];
      tags = {
        nginx = {
          name = "nginx @ ${config.networking.fqdn}";
          color = "#17964a";
        };
        autokuma = {
          name = "Managed by AutoKuma @ ${config.networking.fqdn}";
          color =
            pkgs.runCommand "name" { }
              "printf '#%06X' $(( 0x$(printf '%s' '${config.networking.fqdn}' | sha256sum | cut -c1-6) % 0x1000000 )) > $out"
            |> builtins.readFile;
        };
      };
      monitors =
        genAttrs
          (builtins.filter (kumaVHost: kumaVHost != "localhost") (
            attrNames config.services.nginx.virtualHosts
          ))
          (kumaVHost: {
            type = "http";
            name = kumaVHost;
            description = "nginx Managed by AutoKuma @ ${config.networking.fqdn}";
            expiry_notification = true;
            url = "https://${kumaVHost}";
            accepted_statuscodes = [ "200-399" ];
            notification_name_list = [ "autokuma-matrix" ];
            tag_names = [
              {
                name = "nginx";
                value = kumaVHost;
              }
              {
                name = "autokuma";
                value = "nginx";
              }
            ];
            timeout = 10;
            interval = 20;
            retry_interval = 20;
          });
    };
  };

  systemd.services.autokuma-local.serviceConfig.SupplementaryGroups = "podman";

  sops.secrets.autokuma-env = {
    owner = "root";
    group = "root";
    mode = "0600";

    sopsFile = ../../secrets/autokuma/autokuma.env.secret;
    format = "binary";
    restartUnits = [ "autokuma-local.service" ];
  };

  sops.secrets.autokuma-matrix = {
    owner = "autokuma";
    group = "autokuma";
    mode = "0600";

    sopsFile = ../../secrets/autokuma/autokuma-matrix.toml.secret;
    format = "binary";
    restartUnits = [ "autokuma-local.service" ];
  };
}
