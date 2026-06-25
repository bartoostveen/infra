{ config, ... }:

let
  gitDomain = config.services.forgejo.settings.server.DOMAIN;
in
{
  services.nginx.virtualHosts."go.bartoostveen.nl" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/".return = "302 https://bartoostveen.nl";
      "~ ^/([A-Za-z0-9._-]+)/?$".extraConfig = ''
        if ($arg_go-get = "1") {
            add_header Content-Type "text/html; charset=utf-8";
            return 200 "<!doctype html>
            <html><head>
            <meta name=\"go-import\" content=\"go.bartoostveen.nl/$1 git https://${gitDomain}/bart/$1\">
            <meta name=\"go-source\" content=\"go.bartoostveen.nl/$1 https://${gitDomain}/bart/$1 https://${gitDomain}/bart/$1/tree/main{/dir} https://${gitDomain}/bart/$1/blob/main{/dir}/{file}#L{line}\">
            </head></html>";
        }

        return 302 https://bartoostveen.nl;
      '';
    };
  };
}
