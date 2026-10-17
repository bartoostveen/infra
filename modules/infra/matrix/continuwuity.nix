{
  config,
  pkgs,
  lib,
  wireguard,
  ...
}:

let
  cfg = config.infra.matrix;

  inherit (lib)
    mkIf
    genAttrs
    mkDefault
    ;

  inherit (pkgs.callPackage ./lib.nix { }) mkAutokumaMonitor;

  metricsPort = 48921;
in
{
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.call.enable -> cfg.livekit.enable;
      }
    ];

    services.matrix-continuwuity = {
      enable = true;
      inherit (cfg) package;
      settings.global = {
        server_name = cfg.fqdn;
        new_user_displayname_suffix = "";
        allow_registration = false;
        allow_encryption = true;
        allow_federation = true;
        allow_legacy_media = false;
        allow_prometheus_metrics = true;
        trusted_servers = [
          "utwente.io"
          "starstruck.systems"
          "matrix.org"
        ];

        address = null;
        unix_socket_path = "/run/continuwuity/continuwuity.sock";
        unix_socket_perms = 660;

        url_preview_domain_explicit_allowlist = [
          "i.imgur.com"
          "cdn.discordapp.com"
          "ooye.elisaado.com"
          "media.tenor.com"
          "giphy.com"
          "cdn.nest.rip"
          "ssd-cdn.nest.rip"
          "i.github.com"
          "github.com"
          "fs.omeduostuurcentenneef.nl"
          "files.bartoostveen.nl"
          "party.vitune.app"
        ];

        well_known = {
          client = "https://${cfg.domain}";
          server = "${cfg.domain}:443";
          support_email = "matrix@bartoostveen.nl";
          support_mxid = "@bart:${cfg.fqdn}";
        };
      };
    };

    # Allow federation through http socket to make servers that don't query .well-known work
    networking.firewall.allowedTCPPorts = [ 8448 ];

    services.nginx.virtualHosts =
      let
        socket = "http://unix://${config.services.matrix-continuwuity.settings.global.unix_socket_path}";
      in
      {
        ${cfg.fqdn} = {
          enableACME = mkDefault true;
          forceSSL = mkDefault true;
          locations."/.well-known/matrix/".proxyPass = socket;
        };
        ${cfg.domain} = {
          enableACME = true;
          forceSSL = true;

          locations = {
            "/_continuwuity/metrics".extraConfig = "return 404;";
          }
          //
            genAttrs
              (
                if (cfg.cinny.enable && cfg.cinny.replaceContinuwuity) then
                  [
                    "/_matrix"
                    "/_continuwuity"
                  ]
                else
                  [ "/" ]
              )
              (_: {
                proxyPass = socket;
                rateLimit.enable = false;
              });
        };
      };

    systemd.services.nginx.serviceConfig.SupplementaryGroups = [
      config.services.matrix-continuwuity.group
    ];

    systemd.sockets.continuwuity-proxy = {
      description = "TCP listener for Continuwuity over WireGuard for scraping purposes";
      wantedBy = [ "sockets.target" ];
      listenStreams = [
        "${wireguard.primaryIpOf config.networking.hostName}:${toString metricsPort}"
      ];
      socketConfig = {
        BindToDevice = config.infra.wireguard.interface;
        FreeBind = true;
      };
    };

    systemd.services.continuwuity-proxy = {
      description = "TCP proxy for Continuwuity over WireGuard for scraping purposes";
      requires = [ "continuwuity-proxy.socket" ];
      after = [ "continuwuity-proxy.socket" ];
      serviceConfig = {
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd /run/myapp/myapp.sock";
        DynamicUser = true;
        PrivateTmp = true;
        SupplementaryGroups = [ config.services.matrix-continuwuity.group ];
      };
    };

    infra.extraScrapeConfigs.continuwuity = {
      port = metricsPort;
      metrics_path = "/_continuwuity/metrics";
    };

    infra.autokuma.instances.local = mkAutokumaMonitor cfg.fqdn;

    infra.backup.jobs.state.paths = mkIf cfg.enableBackups [
      config.services.matrix-continuwuity.settings.global.database_path
    ];
  };
}
