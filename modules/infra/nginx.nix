{
  lib,
  inputs,
  ...
}:

let
  inherit (lib) flatten reverseList mkDefault;

  reverseString =
    string: builtins.concatStringsSep "" (flatten (reverseList (builtins.split "" string)));
in
{
  imports = [
    inputs.srvos.nixosModules.mixins-nginx
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security" + "@" + (reverseString "feennetnecruutsoudemo") + ".nl";

  services.nginx = {
    enable = true;
    enableReload = true;

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    statusPage = true;

    clientMaxBodySize = "128m";

    defaultListenAddresses = [
      "0.0.0.0"
      "[::0]"
    ];

    commonHttpConfig = ''
      log_format main '$remote_addr - $remote_user [$time_local] '
                      '"$request" $status $body_bytes_sent '
                      '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

      access_log /var/log/nginx/access.log main;
      error_log /var/log/nginx/error.log warn;
    '';
  };

  services.prometheus.exporters = {
    nginx.enable = mkDefault true;
    nginxlog = mkDefault {
      enable = true;
      settings.namespaces = [
        {
          name = "default";
          format = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\"";
          source.files = [
            "/var/log/nginx/access.log"
            "/var/log/nginx/error.log"
          ];
        }
      ];
    };
  };

  systemd.services.prometheus-nginxlog-exporter.serviceConfig.SupplementaryGroups = [ "nginx" ];

  services.fail2ban.jails = {
    nginx-http-auth = ''
      enabled = true
      filter = nginx-http-auth
      logpath = /var/log/nginx/error.log
      maxretry = 5
    '';

    nginx-badbots = ''
      enabled = true
      filter = nginx-badbots
      logpath = /var/log/nginx/access.log
      maxretry = 2
    '';
  };
}
