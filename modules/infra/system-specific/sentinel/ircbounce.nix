{ config, lib, ... }:

let
  inherit (lib) genAttrs concatStringsSep attrsToList;

  vHost = "ircbounce.bartoostveen.nl";
  certDir = config.security.acme.certs.${vHost}.directory;
  cert = "${certDir}/cert.pem";
  key = "${certDir}/key.pem";
in
{
  services.nginx.virtualHosts.${vHost} = {
    enableACME = true;
    forceSSL = true;

    locations."/".proxyPass = "http://127.0.0.1:${toString config.services.znc.config.Listener.l.Port}";
  };

  services.znc = {
    enable = true;
    mutable = false;
    useLegacyConfig = false;
    openFirewall = true;
    config = {
      SSLCertFile = cert;
      SSLKeyFile = key;
      TrustedProxy = [
        "127.0.0.1"
        "::1"
      ];

      Listener = {
        l = {
          AllowIRC = true;
          AllowWeb = true;
          Port = 5000;
          SSL = true;
          IPv4 = true;
          IPv6 = false;
          URIPrefix = "/";
        };
        l6 = {
          AllowIRC = true;
          AllowWeb = true;
          Port = 5000;
          SSL = true;
          IPv4 = false;
          IPv6 = true;
          URIPrefix = "/";
        };
      };
      LoadModule = [
        "adminlog"
        "fail2ban"
        "lastseen"
        "log"
        "notify_connect"
        "saslplainauth"
        "webadmin"
      ];
      User.bart = {
        Admin = true;
        AutoClearChanBuffer = false;
        AutoClearQueryBuffer = false;
        Buffer = 1000;
        QuitMsg = "Quit";
        RealName = "Bart";

        Pass.password = {
          Method = "sha256";
          Hash = "23fe43fd6af0c309ba2eb51094bbf4bc3170cff996fe5424189224b8234a8cca";
          Salt = "5aW1!NMlI_ZB:/4eLuv2";
        };
        Network.ircnet = {
          Server = "openirc.snt.utwente.nl 6667";
          Chan = genAttrs [ "#snt" ] (_name: {
            Buffer = 1000;
          });
          Nick = "bart_irc";
          LoadModule = [
            "savebuff"
          ];
          RealName = "Bart Oostveen";
        };
        Network.libera = {
          Server = "irc.eu.libera.chat +6697";
          Chan =
            genAttrs
              [
                "#libera"
                "#nixos"
                "#nixos-dev"
                "#nixos-chat"
              ]
              (_name: {
                Buffer = 1000;
              });
          LoadModule = [
            "sasl"
            "savebuff"
          ];
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    113 # oidentd
  ];

  users.users.znc.extraGroups = [ "nginx" ];

  systemd.services.znc.after = [ "acme-${vHost}.service" ];

  services.oidentd.enable = true;
  environment.etc."oidentd.conf".text =
    let
      response = {
        root = "UNKNOWN";
        znc = "bart";
      };
    in
    ''
      default {
        default {
          deny spoof
          deny spoof_all
          deny spoof_privport
          allow random
          allow random_numeric
          allow numeric
          allow hide
        }
      }

      ${concatStringsSep "\n" (
        map (
          { name, value }:
          ''
            user ${name} {
              default {
                force reply "${value}"
              }
            }
          ''
        ) (attrsToList response)
      )}
    '';
}
