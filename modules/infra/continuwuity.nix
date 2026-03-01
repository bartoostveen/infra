{
  config,
  pkgs,
  personalPkgs,
  lib,
  ...
}:

let
  fqdn = "bartoostveen.nl";
  domain = "matrix.${fqdn}";
  rtcDomain = "matrix-rtc.${fqdn}";

  inherit (lib) genAttrs getExe;

  keyFile = config.sops.secrets.livekit-keys.path;

  mkElementCall =
    elementCallConfig:
    pkgs.element-call.overrideAttrs {
      postInstall = ''
        install ${pkgs.writers.writeJSON "element-call.json" elementCallConfig} $out/config.json
      '';
    };
in
{
  services.matrix-continuwuity = {
    enable = true;
    settings.global = {
      server_name = fqdn;
      new_user_displayname_suffix = "";
      allow_registration = false;
      allow_encryption = true;
      allow_federation = true;
      trusted_servers = [ "matrix.org" ];

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
      ];

      well_known = {
        client = "https://${domain}";
        server = "${domain}:443";
        support_email = "matrix@bartoostveen.nl";
        support_mxid = "@bart:bartoostveen.nl";
        rtc_focus_server_urls = [
          {
            type = "livekit";
            livekit_service_url = "https://${rtcDomain}/livekit/jwt";
          }
        ];
      };

      turn_uris = [
        "turn:${rtcDomain}:${toString config.services.livekit.settings.turn.udp_port}?transport=udp"
        "turns:${rtcDomain}:${toString config.services.livekit.settings.turn.tls_port}?transport=udp"
      ];
      turn_secret_file = config.sops.secrets.turn.path;
    };
  };

  services.lk-jwt-service = {
    enable = true;
    inherit keyFile;
    livekitUrl = "wss://${rtcDomain}/livekit/sfu";
  };

  services.livekit =
    let
      certDir = config.security.acme.certs.${rtcDomain}.directory;
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
          domain = rtcDomain;
        };
      };
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

  services.nginx.virtualHosts =
    let
      socket = "http://unix://${config.services.matrix-continuwuity.settings.global.unix_socket_path}";
      cinny = personalPkgs.cinny.override {
        conf = {
          homeserverList = [
            fqdn
            "ooye.elisaado.com"
            "utwente.io"
            "matrix.org"
            "github.com"
            "fs.omeduostuurcentenneef.nl"
            "files.bartoostveen.nl"
            "party.vitune.app"
          ];
          defaultHomeserver = 0;
          allowCustomHomeservers = true;
          featuredCommunities = { };
          hashRouter.enabled = true;
        };
      };
      cinnies = genAttrs (map (n: "cinny${toString n}.${fqdn}") (lib.range 0 9)) (_: {
        enableACME = true;
        forceSSL = true;

        locations."/".root = "${cinny}";
      });
    in
    {
      ${fqdn}.locations."/.well-known/matrix/".proxyPass = socket;
      "call.${fqdn}" = {
        enableACME = true;
        forceSSL = true;
        root = "${mkElementCall {
          default_server_config."m.homeserver" = {
            base_url = "https://matrix.${fqdn}";
            server_name = fqdn;
          };
          features.feature_use_device_session_member_events = true;
          livekit.livekit_service_url = "https://${rtcDomain}/livekit/jwt";
          matrix_rtc_session = {
            delayed_leave_event_delay_ms = 18000;
            delayed_leave_event_restart_ms = 4000;
            membership_event_expiry_ms = 180000000;
            network_error_retry_ms = 100;
            wait_for_key_rotation_ms = 3000;
          };
          media_devices = {
            enable_audio = false;
            enable_video = false;
          };
          app_prompt = false;
          ssla = "https://static.element.io/legal/element-software-and-services-license-agreement-uk-1.pdf";
        }}";
        locations."/".extraConfig = ''
          try_files $uri /$uri /index.html;
        '';
      };
      ${domain} = {
        enableACME = true;
        forceSSL = true;

        locations."/".root = "${cinny}";
        locations."/_matrix".proxyPass = socket;
      };
      ${rtcDomain} = {
        enableACME = true;
        forceSSL = true;
        locations."^~ /livekit/jwt/".proxyPass =
          "http://127.0.0.1:${toString config.services.lk-jwt-service.port}/";
        locations."^~ /livekit/sfu/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.livekit.settings.port}/";
          proxyWebsockets = true;
        };
      };
      "element.${fqdn}" = {
        enableACME = true;
        forceSSL = true;

        locations."/".root = "${pkgs.element-web}";
      }; 
    }
    // cinnies;

  systemd.services.nginx.serviceConfig.SupplementaryGroups = [
    config.services.matrix-continuwuity.group
  ];
  systemd.services.continuwuity.serviceConfig.SupplementaryGroups = [ "matrix-livekit" ];
  systemd.services.livekit.serviceConfig.SupplementaryGroups = [ "nginx" ];

  systemd.services.alertmanager-matrix = {
    description = "Alertmanager Matrix bot";
    after = [
      "network.target"
      "continuwuity.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = getExe pkgs.local.alertmanager-matrix;
      EnvironmentFile = config.sops.secrets.alertmanager-matrix-env.path;
      Restart = "on-failure";
      DynamicUser = true;
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MountAPIVFS = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateUsers = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = "strict";
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = 27;
    };
  };

  users.users =
    genAttrs [ "livekit" "lk-jwt-service" ] (_name: {
      isSystemUser = true;
      group = "matrix-livekit";
    })
    // {
      alertmanager-matrix = {
        isSystemUser = true;
        group = "alertmanager-matrix";
      };
    };
  users.groups.matrix-livekit = { };
  users.groups.alertmanager-matrix = { };

  sops.secrets.livekit-keys = {
    sopsFile = ../../secrets/livekit-keys.secret;
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
    sopsFile = ../../secrets/turn.secret;
    owner = "livekit";
    group = "matrix-livekit";
    format = "binary";
    mode = "440";
    restartUnits = [
      "livekit.service"
      "lk-jwt-service.service"
    ];
  };

  sops.secrets.alertmanager-matrix-env = {
    sopsFile = ../../secrets/alertmanager-matrix.env.secret;
    owner = "alertmanager-matrix";
    group = "alertmanager-matrix";
    format = "binary";
    mode = "440";
    restartUnits = [ "alertmanager-matrix.service" ];
  };
}
