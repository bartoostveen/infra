{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkAfter
    mkForce
    listToAttrs
    nameValuePair
    ;

  fqdn = "bartoostveen.nl";
  domain = "hydra.${fqdn}";

  metricsPort = 9199;
  anubisMetricsPort = 11024;

  # TODO
  machines = [
    "bart-pc"
  ];
in
{
  imports = [
    inputs.hydra.nixosModules.hydra
    inputs.hydra.nixosModules.queue-runner
  ];

  services.hydra-dev = {
    enable = true;
    hydraURL = "https://${domain}";
    notificationSender = "hydra@${fqdn}";
    useSubstitutes = true;
    # TODO
    # store_uri =
    extraConfig = ''
      max_concurrent_evals = 1
      max_db_connections = 350

      evaluator_workers = 2
      evaluator_max_memory_size = 4096

      upload_logs_to_binary_cache = false
      allow_import_from_derivation = true

      <dynamicruncommand>
        enable = 1
      </dynamicruncommand>

      queue_runner_endpoint = http://${config.services.hydra-queue-runner-dev.rest.address}:${toString config.services.hydra-queue-runner-dev.rest.port}

      <hydra_notify>
        <prometheus>
          listen_address = 0.0.0.0
          port = ${toString metricsPort}
        </prometheus>
      </hydra_notify>
    '';
  };

  services.hydra-queue-runner-dev = {
    enable = true;
    package = mkForce inputs.hydra.packages.${pkgs.stdenv.hostPlatform.system}.hydra-queue-runner;
    settings = {
      machineFreeFn = "DynamicWithMaxJobLimit";
      stepSortFn = "WithCriticalPath";
      tokenPaths = map (machine: config.sops.secrets."${machine}-queue-runner-token".path) machines;
    };
  };

  services.nginx.virtualHosts = {
    "hydra.bartoostveen.nl" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          proxyPass = "http://unix://${config.services.anubis.instances.hydra.settings.BIND}";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 0;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_buffers 32 8k;
            proxy_buffer_size 16k;
            proxy_busy_buffers_size 24k;
          '';
        };
        "/static/".alias = "${config.services.hydra-dev.package}/libexec/hydra/root/static/";
        "=/robots.txt".alias = pkgs.writeText "hydra.bartoostveen.nl-robots.txt" ''
          User-agent: *
          Disallow: /
          Allow: /$
        '';
      };
    };
    "queue.hydra.bartoostveen.nl" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/metrics".extraConfig = "return 404;";
        "/".extraConfig = ''
          # This is necessary so that grpc connections do not get closed early
          # see https://stackoverflow.com/a/67805465
          client_body_timeout 31536000s;
          client_max_body_size 0;

          grpc_pass grpc://${config.services.hydra-queue-runner-dev.grpc.address}:${toString config.services.hydra-queue-runner-dev.grpc.port};

          grpc_read_timeout 31536000s; # 1 year in seconds
          grpc_send_timeout 31536000s; # 1 year in seconds
          grpc_socket_keepalive on;

          # Builders reuse one long-lived HTTP/2 channel for many RPCs. The
          # default keepalive_requests (1000) makes nginx GOAWAY mid-stream,
          # cancelling in-flight RPCs and aborting builds.
          keepalive_requests 1000000;
          keepalive_timeout 600s;

          grpc_set_header Host $host;
          grpc_set_header X-Real-IP $remote_addr;
          grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          grpc_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  sops.secrets = listToAttrs (
    map (
      machine:
      nameValuePair "${machine}-queue-runner-token" {
        sopsFile = ../../../secrets/hydra/${machine}-queue-runner-token.secret;
        owner = "hydra-queue-runner";
        group = "hydra";
        format = "binary";
        mode = "0400";
        restartUnits = [ "hydra-queue-runner-dev.service" ];
      }
    ) machines
  );

  programs.ssh.extraConfig = mkAfter ''
    ServerAliveInterval 120
    TCPKeepAlive yes
  '';

  services.openssh.knownHosts = {
    "10.0.0.7".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3bxbppcuf+FdbIgG7v1ndZPUeh5KEE0bEjhHmfupnS";
  };

  services.anubis.instances.hydra.settings = {
    BIND = "/run/anubis/anubis-hydra/anubis-hydra.sock";
    TARGET = "http://localhost:${toString config.services.hydra-dev.port}";
    METRICS_BIND = "0.0.0.0:${toString anubisMetricsPort}";
    METRICS_BIND_NETWORK = "tcp";
  };

  systemd.services.hydra-notify.enable = mkForce false;

  infra.extraScrapeConfigs = {
    hydra.port = metricsPort;
    hydra-queue-runner = { inherit (config.services.hydra-queue-runner-dev.rest) port; };
    abubis-hydra.port = anubisMetricsPort;
  };
}
