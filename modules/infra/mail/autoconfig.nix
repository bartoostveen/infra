{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) lists mkIf;
  inherit (lists) remove;

  cfg = config.mailserver;
  metaCfg = config.infra.mail;
in
{
  services.nginx.virtualHosts."autoconfig.${cfg.systemDomain}" = mkIf metaCfg.autoconfig {
    enableACME = true;
    forceSSL = true;
    serverAliases = cfg.domains |> remove cfg.systemDomain |> map (s: "autoconfig.${s}");
    locations."= /mail/config-v1.1.xml".root = pkgs.writeTextDir "mail/config-v1.1.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>

      <clientConfig version="1.1">
       <emailProvider id="${cfg.systemDomain}">
         <domain>${cfg.systemDomain}</domain>
         <displayName>${cfg.systemName}</displayName>
         <displayShortName>${cfg.systemDomain}</displayShortName>
         <incomingServer type="imap">
           <hostname>${cfg.fqdn}</hostname>
           <port>993</port>
           <socketType>SSL</socketType>
           <authentication>password-cleartext</authentication>
           <username>%EMAILADDRESS%</username>
         </incomingServer>
         <outgoingServer type="smtp">
           <hostname>${cfg.fqdn}</hostname>
           <port>465</port>
           <socketType>SSL</socketType>
           <authentication>password-cleartext</authentication>
           <username>%EMAILADDRESS%</username>
         </outgoingServer>
       </emailProvider>
      </clientConfig>
    '';
  };
}
