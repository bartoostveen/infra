{
  config,
  lib,
  inputs,
  ...
}:

let
  reverseString =
    string: builtins.concatStringsSep "" (lib.flatten (lib.reverseList (builtins.split "" string)));
in
{
  imports = [
    inputs.srvos.nixosModules.mixins-nginx
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security" + "@" + (reverseString "feennetnecruutsoudemo") + ".nl";

  services.nginx = {
    enable = true;

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    statusPage = true;

    clientMaxBodySize = "128m";

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    defaultListenAddresses = [
      "0.0.0.0"
      "[::0]"
      "100.64.0.2"
    ];
  };

  # Skip cloudflare when resolving own virtualHosts for some reason
  networking.hosts."127.0.0.1" = builtins.attrNames config.services.nginx.virtualHosts;
}
