{
  config,
  lib,
  pkgs,
  inputs,
  wireguard,
  flakeRoot,
  ...
}:

let
  inherit (builtins)
    any
    ;

  inherit (lib)
    # keep-sorted start
    attrNames
    genAttrs
    hasInfix
    mkDefault
    optional
    optionalAttrs
    # keep-sorted end
    ;

  vhosts =
    attrNames config.services.nginx.virtualHosts
    |> builtins.filter (vhost: vhost != "localhost" && !(hasInfix "*." vhost));
  isCinny = s: hasInfix "sable" s || hasInfix "cinny" s;
  hasCinny = any isCinny vhosts;
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
        url = "http://${wireguard.primaryIpOf "sentinel"}:${toString inputs.self.nixosConfigurations.sentinel.config.services.uptime-kuma.settings.PORT}";
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
      }
      // optionalAttrs hasCinny {
        cinny = {
          name = "Cinny @ ${config.networking.fqdn}";
          color = "#0c67a0";
        };
      };

      monitors = {
        nginx-group = {
          type = "group";
          name = "NGINX @ ${config.networking.fqdn}";
          description = "All nginx virtual hosts for ${config.networking.hostName}";
          interval = 20;
          retry_interval = 20;
          tag_names = [
            {
              name = "autokuma";
              value = "nginx";
            }
          ];
        };
      }
      // optionalAttrs hasCinny {
        cinny-group = {
          type = "group";
          name = "cinny @ ${config.networking.fqdn}";
          description = "All cinny virtual hosts for ${config.networking.hostName}";
          interval = 20;
          retry_interval = 20;
          parent_name = "nginx-group";
          tag_names = [
            {
              name = "autokuma";
              value = "cinny";
            }
          ];
        };
      }
      // genAttrs vhosts (vhost: {
        type = "http";
        name = vhost;
        description = "nginx Managed by AutoKuma @ ${config.networking.fqdn}";
        expiry_notification = true;
        url = "https://${vhost}";
        accepted_statuscodes = [ "200-399" ];
        notification_name_list = [ "autokuma-matrix" ];
        tag_names = [
          {
            name = "nginx";
            value = vhost;
          }
          {
            name = "autokuma";
            value = "nginx";
          }
        ]
        ++ optional (isCinny vhost) {
          name = "cinny";
        };
        timeout = 10;
        interval = 20;
        retry_interval = 20;
        parent_name = if isCinny vhost then "cinny-group" else "nginx-group";
      });
    };
  };

  systemd.services.autokuma-local.serviceConfig.SupplementaryGroups = "podman";

  sops.secrets.autokuma-env = {
    owner = "root";
    group = "root";
    mode = "0600";

    sopsFile = /${flakeRoot}/secrets/autokuma/autokuma.env.secret;
    format = "binary";
    restartUnits = [ "autokuma-local.service" ];
  };

  sops.secrets.autokuma-matrix = {
    owner = "autokuma";
    group = "autokuma";
    mode = "0600";

    sopsFile = /${flakeRoot}/secrets/autokuma/autokuma-matrix.toml.secret;
    format = "binary";
    restartUnits = [ "autokuma-local.service" ];
  };
}
