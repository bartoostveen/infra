{
  inputs,
  lib,
  config,
  options,
  ...
}:

let
  inherit (builtins) elemAt;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    mkDefault
    recursiveUpdate
    split
    flip
    ;
  inherit (types) int str path;

  cfg = config.infra.authentik;

  inherit (config.services.authentik) authentikComponents;
in
{
  imports = [
    inputs.authentik.nixosModules.default
  ];

  options.infra.authentik = {
    enable = mkEnableOption "authentik";
    enablePrometheus = mkEnableOption "Prometheus monitoring of authentik";
    environmentFile = mkOption {
      description = "File outside of nix store containing environment variables such as the email passwords";
      type = path;
    };
    metricsPort = mkOption {
      description = "Prometheus metrics port";
      type = int;
      default = 64151;
    };
    ldapMetricsPort = mkOption {
      description = "Prometheus LDAP metrics port";
      type = int;
      default = 64152;
    };
    domain = mkOption {
      description = "Domain of the authentik server";
      type = str;
      default = "auth.bartoostveen.nl";
    };
    emailHost = mkOption {
      description = "Email host";
      type = str;
      default = "bartoostveen.nl";
    };
    email = mkOption {
      description = "Email of the authentik server";
      type = str;
      default = "auth@bartoostveen.nl";
    };
    nginx = {
      inherit (options.services.nginx.virtualHosts.type.getSubOptions { }) rateLimit connectionLimit;
    };
  };

  config = mkIf cfg.enable {
    infra.authentik.nginx = {
      rateLimit.burst = mkDefault 2000;
      connectionLimit.connections = mkDefault 1000;
    };

    services.authentik = {
      enable = true;
      inherit (cfg) environmentFile;
      worker.listenMetrics = "0.0.0.0:${toString cfg.metricsPort}";
      settings = {
        email = {
          host = cfg.emailHost;
          port = 587;
          username = cfg.email;
          use_tls = true;
          use_ssl = false;
          from = cfg.email;
        };
        disable_startup_analytics = true;
        avatars = "initials";
      };
      nginx = {
        enable = true;
        enableACME = true;
        host = cfg.domain;
      };
    };

    services.nginx.virtualHosts.${cfg.domain} =
      let
        cacheBustParam = baseNameOf authentikComponents.frontend |> split "-" |> flip elemAt 0;
        cacheBustFilter = fileType: "sub_filter '.${fileType}' '.${fileType}?revision=${cacheBustParam}';";
        subFilter = ''
          sub_filter_types text/html;
          ${cacheBustFilter "js"}
          ${cacheBustFilter "css"}
          sub_filter_once off;
        '';
      in
      recursiveUpdate {
        enableHSTS = mkDefault true;
        locations."/".extraConfig = ''
          add_header Cache-Control "no-cache, no-store, must-revalidate";
          add_header Pragma "no-cache";
          add_header Expires "0";
          ${subFilter}
          proxy_set_header Accept-Encoding "";
        '';
        locations."/static/".extraConfig = ''
          ${subFilter}
        '';
      } cfg.nginx;

    services.authentik-ldap = {
      enable = true;
      inherit (cfg) environmentFile;
      listenMetrics = "0.0.0.0:${toString cfg.ldapMetricsPort}";
    };

    infra.extraScrapeConfigs = mkIf cfg.enablePrometheus {
      authentik.port = cfg.metricsPort;
      authentik-ldap.port = cfg.ldapMetricsPort;
    };

    users.users.authentik = {
      isSystemUser = true;
      group = "authentik";
    };
    users.groups.authentik = { };

    users.users.authentik-ldap = {
      isSystemUser = true;
      group = "authentik";
    };

    networking.firewall.allowedTCPPorts = [
      3389 # LDAP
      6636 # LDAPS
    ];

    infra.backup.jobs.state.paths = [ config.services.authentik.settings.storage.media.file.path ];
  };
}
