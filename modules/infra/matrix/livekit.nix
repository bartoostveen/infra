{ config, lib, ... }:

let
  keyFile = config.sops.secrets.livekit-keys.path;
  cfg = config.infra.matrix;

  inherit (lib) mkIf genAttrs;
in
{
  config = mkIf (cfg.enable && cfg.livekit.enable) {
    services.lk-jwt-service = {
      enable = true;
      inherit keyFile;
      livekitUrl = "wss://${cfg.livekit.domain}/livekit/sfu";
    };

    services.livekit =
      let
        certDir = config.security.acme.certs.${cfg.livekit.domain}.directory;
        cert = "${certDir}/cert.pem";
        key = "${certDir}/key.pem";
      in
      {
        enable = true;
        openFirewall = true;
        inherit keyFile;
        settings = {
          rtc = {
            tcp_port = 7881;
            port_range_start = 50100;
            port_range_end = 50200;
            use_external_ip = true;
            enable_loopback_candidate = false;
          };
          turn = {
            enabled = true;
            udp_port = 3479;
            tls_port = 3480;
            cert_file = cert;
            key_file = key;
            external_tls = false;
            relay_range_start = 50300;
            relay_range_end = 50400;
            inherit (cfg) domain;
          };
        };
      };

    services.nginx.virtualHosts.${cfg.livekit.domain} = {
      enableACME = true;
      forceSSL = true;
      locations."^~ /livekit/jwt/".proxyPass =
        "http://127.0.0.1:${toString config.services.lk-jwt-service.port}/";
      locations."^~ /livekit/sfu/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.livekit.settings.port}/";
        proxyWebsockets = true;
      };
    };

    services.matrix-continuwuity.settings.global = {
      matrix_rtc.foci = [
        {
          type = "livekit";
          livekit_service_url = "https://${cfg.livekit.domain}/livekit/jwt";
        }
      ];

      turn_uris = [
        "turn:${cfg.livekit.domain}:${toString config.services.livekit.settings.turn.udp_port}?transport=udp"
        "turns:${cfg.livekit.domain}:${toString config.services.livekit.settings.turn.tls_port}?transport=udp"
      ];
      turn_secret_file = config.sops.secrets.turn.path;
    };

    networking.firewall = {
      allowedUDPPortRanges = [
        {
          from = config.services.livekit.settings.rtc.port_range_start;
          to = config.services.livekit.settings.rtc.port_range_end;
        }
        {
          from = config.services.livekit.settings.turn.relay_range_start;
          to = config.services.livekit.settings.turn.relay_range_end;
        }
      ];
      allowedUDPPorts = [ config.services.livekit.settings.turn.udp_port ];
      allowedTCPPorts = [ config.services.livekit.settings.rtc.tcp_port ];
    };

    systemd.services.continuwuity.serviceConfig.SupplementaryGroups = [ "matrix-livekit" ];
    systemd.services.livekit.serviceConfig.SupplementaryGroups = [ "nginx" ];

    users.users = genAttrs [ "livekit" "lk-jwt-service" ] (_name: {
      isSystemUser = true;
      group = "matrix-livekit";
    });
    users.groups.matrix-livekit = { };

    sops.secrets.livekit-keys = {
      sopsFile = ../../../secrets/matrix/livekit-keys.bart-server.secret;
      owner = "livekit";
      group = "matrix-livekit";
      format = "binary";
      mode = "440";
      restartUnits = [
        "livekit.service"
        "lk-jwt-service.service"
      ];
    };

    sops.secrets.turn = {
      sopsFile = ../../../secrets/matrix/turn.bart-server.secret;
      owner = "livekit";
      group = "matrix-livekit";
      format = "binary";
      mode = "440";
      restartUnits = [
        "livekit.service"
        "lk-jwt-service.service"
      ];
    };
  };
}
