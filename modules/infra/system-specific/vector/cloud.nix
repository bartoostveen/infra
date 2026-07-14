{
  pkgs,
  config,
  ...
}:

let
  domain = "popkoorklankkleur.nl";
  fqdn = "cloud.${domain}";
  collaboraDomain = "collabora.${fqdn}";
in
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud34;
    hostName = fqdn;
    secretFile = config.sops.secrets.nextcloud-secrets.path;
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
      dbtype = "pgsql";
    };
    database.createLocally = true;
    configureRedis = true;
    https = true;
    maxUploadSize = "5G";
    settings = {
      allow_local_remote_servers = true;
      mail_smtpmode = "smtp";
      mail_smtpauth = true;
      mail_smtphost = domain;
      mail_smtpport = 465;
      mail_smtpsecure = "ssl";
      mail_smtpname = "cloud@${domain}";
      mail_from_address = "cloud";
      mail_domain = domain;
      defaultapp = "files";
      "overwrite.cli.url" = "https://${fqdn}";
    };
    phpOptions = {
      "opcache.memory_consumption" = "128";
      "opcache.interned_strings_buffer" = "25";
      "opcache.max_accelerated_files" = "4000";
      "opcache.revalidate_freq" = "60";
      "opcache.enable_cli" = "1";
    };
    extraApps = {
      inherit (pkgs.nextcloud33Packages.apps) user_oidc groupfolders richdocuments;
    };
    extraAppsEnable = true;
  };

  services.nginx.virtualHosts = {
    ${fqdn} = {
      forceSSL = true;
      enableACME = true;
      rateLimit.enable = false;
    };

    ${collaboraDomain} = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          proxyPass = "http://localhost:${toString config.services.collabora-online.port}";
          proxyWebsockets = true;
        };
        "^~ /cool/getMetrics".return = "404";
      };
    };
  };

  services.collabora-online = {
    enable = true;
    settings = {
      net.listen = "0.0.0.0";
      ssl = {
        termination = true;
        enable = false;
      };
      security.enable_metrics_unauthenticated = true;
      remote_font_config = [
        { url = "https://cloud.popkoorklankkleur.nl/apps/richdocuments/settings/fonts.json"; }
      ];
    };
  };

  infra.extraScrapeConfigs.collabora = {
    port = config.services.collabora-online.port;
    metrics_path = "/cool/getMetrics";
  };

  infra.backup.jobs.state.paths = [ config.services.nextcloud.home ];

  sops.secrets.nextcloud-admin-pass = {
    format = "binary";
    sopsFile = ../../../../secrets/nextcloud-admin-pass.vector.secret;

    owner = "nextcloud";
    group = "nextcloud";
    mode = "0660";
  };

  sops.secrets.nextcloud-secrets = {
    format = "binary";
    sopsFile = ../../../../secrets/nextcloud-secrets.json.vector.secret;

    owner = "nextcloud";
    group = "nextcloud";
    mode = "0660";
  };
}
