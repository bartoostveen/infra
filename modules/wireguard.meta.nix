{ lib, ... }:

let
  inherit (lib)
    splitString
    ;
  first = list: builtins.elemAt list 0;
in
rec {
  listenPort = 51820;

  connectivity = import ./connectivity.meta.nix { inherit lib; };

  nodes = {
    bart-server = {
      ips = [
        "10.0.0.1/32"
        "fd42:42:42::1/128"
      ];
      allowedIPs = [
        "10.0.0.0/24"
        "fd42:42:42::/64"
      ];
      endpoint = "${connectivity.ipsFor "bart-server" |> first}:${toString listenPort}";
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

    atlas = {
      ips = [
        "10.0.0.4/32"
        "fd42:42:42::4/128"
      ];
    };

    vector = {
      ips = [
        "10.0.0.5/32"
        "fd42:42:42::5/128"
      ];
      endpoint = "${connectivity.ipsFor "vector" |> first}:${toString listenPort}";
    };
    bart-windows-vm = {
      ips = [
        "10.0.0.6/32"
        "fd42:42:42::6/128"
      ];
    };

    bart-pc = {
      ips = [
        "10.0.0.7/32"
        "fd42:42:42::7/128"
      ];
    };
  };

  primaryIpOf = name: nodes.${name}.ips |> first |> splitString "/" |> first;
}
