{
  config,
  lib,
  wireguard,
  ...
}:

let
  cfg = config.infra.wireguard;

  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    mkDefault
    mkForce
    attrsToList
    ;

  inherit (wireguard) listenPort nodes;

  peersFor =
    hostname:
    attrsToList nodes
    |> builtins.filter (
      { name, value }: name != hostname && (nodes.${hostname} ? endpoint || value ? endpoint)
    )
    |> map (
      { name, value }:
      {
        inherit name;
        publicKey = builtins.readFile ../secrets/wireguard/${name}.public;
        allowedIPs =
          if (value ? allowedIPs && !(nodes.${hostname} ? allowedIPs)) then value.allowedIPs else value.ips;
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
    networking.firewall = {
      allowedUDPPorts = [ listenPort ];
      trustedInterfaces = [ cfg.interface ];
    };
    networking.wireguard = {
      useNetworkd = mkDefault true;
      interfaces.${cfg.interface} = {
        inherit (nodes.${cfg.host}) ips;
        inherit listenPort;
        privateKeyFile = config.sops.secrets.${sopsSecret}.path;
        peers = peersFor cfg.host;
      };
    };

    sops = {
      useSystemdActivation = mkForce true;
      secrets.${sopsSecret} = {
        format = "binary";
        sopsFile = ../secrets/wireguard/private.${cfg.host}.secret;
        restartUnits = mkIf config.networking.wireguard.useNetworkd [ "systemd-networkd.service" ];
      };
    };

    systemd.services.systemd-networkd = mkIf config.networking.wireguard.useNetworkd {
      requires = [ "sops-install-secrets.service" ];
      after = [ "sops-install-secrets.service" ];
    };
  };
}
