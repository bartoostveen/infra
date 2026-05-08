{
  config,
  lib,
  wireguard,
  ...
}:

let
  inherit (lib)
    mkIf
    nameValuePair
    concatStringsSep
    listToAttrs
    ;

  inherit (wireguard) nodes;
in
{
  infra.autokuma.instances.local = mkIf config.infra.wireguard.enable {
    tags.wireguard = {
      name = "Wireguard";
      color = "#88171a";
    };
    monitors =
      map (
        peer:
        nameValuePair "wireguard-${peer.name}" {
          type = "ping";
          name = "${peer.name} - Wireguard ping (${concatStringsSep ", " nodes.${peer.name}.ips})";
          description = "Managed by AutoKuma";
          timeout = 20;
          interval = 10;
          retry_interval = 10;
          max_retries = 1;
          packet_size = 56;
          notification_name_list = [ "autokuma-matrix" ];
          hostname = wireguard.primaryIpOf peer.name;
          tag_names = [
            {
              name = "autokuma";
              value = "Wireguard";
            }
            {
              name = "wireguard";
              value = peer.name;
            }
          ];
        }
      ) (config.networking.wireguard.interfaces.${config.infra.wireguard.interface}.peers)
      |> listToAttrs;
  };
}
