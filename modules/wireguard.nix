{ config, lib, ... }:

let
  cfg = config.infra.wireguard;

  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    mkDefault
    attrsToList
    ;

  metadata = {
    bart-server = {
      ips = [
        "10.0.0.1/32"
        "fd42:42:42::1/128"
      ];
      allowedIPs = [
        "10.0.0.0/24"
        "fd42:42:42::/64"
      ];
      endpoint = "78.46.150.107:${toString listenPort}";
    };

    bart-laptop-new = {
      ips = [
        "10.0.0.2/32"
        "fd42:42:42::2/128"
      ];
    };

    bart-phone = {
      ips = [
        "10.0.0.3/32"
        "fd42:42:42::3/128"
      ];
    };
  };

  listenPort = 51820;

  peersFor =
    hostname:
    attrsToList metadata
    |> builtins.filter ({ name, ... }: name != hostname)
    |> map (
      { name, value }:
      {
        inherit name;
        publicKey = builtins.readFile ../secrets/wireguard/${name}.public;
        allowedIPs = if (value ? allowedIPs) then value.allowedIPs else value.ips;
        endpoint = mkIf (value ? endpoint) value.endpoint;
        persistentKeepalive = 25;
      }
    );

  sopsSecret = "wg-${cfg.host}";
in
{
  options.infra.wireguard = {
    enable = mkEnableOption "WireGuard integration";
    host = mkOption {
      description = "Hostname of this host";
      type = types.str;
      default = config.networking.hostName;
      defaultText = "networking.hostName";
      example = "foo";
    };
    interface = mkOption {
      description = "Name of the WireGuard interface";
      type = types.str;
      default = "wg-infra";
      example = "wg0";
    };
  };
  config = mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ listenPort ];
    networking.wireguard = {
      useNetworkd = mkDefault true;
      interfaces.${cfg.interface} = {
        inherit (metadata.${cfg.host}) ips;
        inherit listenPort;
        privateKeyFile = config.sops.secrets.${sopsSecret}.path;
        peers = peersFor cfg.host;
      };
    };

    sops.secrets.${sopsSecret} = {
      format = "binary";
      sopsFile = ../secrets/wireguard/${cfg.host}.private.secret;
      reloadUnits = mkIf config.networking.wireguard.useNetworkd [ "systemd-networkd.service" ];
    };
  };
}
