{
  config,
  ...
}:

{
  services.immich.enable = true;

  services.nginx.virtualHosts."images.bartoostveen.nl" = {
    enableACME = true;
    forceSSL = true;
    rateLimit.burst = 1000;
    locations."/" = {
      proxyPass = "http://${config.services.immich.host}:${toString config.services.immich.port}";
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
  };
}
