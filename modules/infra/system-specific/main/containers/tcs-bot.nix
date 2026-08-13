{ pkgs, ... }:

{
  services.nginx.virtualHosts."tcsdiscord.bartoostveen.nl" = {
    forceSSL = true;
    enableACME = true;
    locations."/".root = pkgs.writeTextDir "/index.html" (
      builtins.readFile ./tcs-bot-temporarily-unavailable.html
    );
  };
}
