{ lib, inputs, ... }:

let
  inherit (lib) concatStringsSep splitString trim;
  inherit (builtins) readFile filter;
in
{
  networking.nat.enable = true;
  networking.domain = "bartoostveen.nl";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall.extraCommands = ''
    ${
      readFile "${inputs.ip-bans}/bans.txt"
      |> splitString "\n"
      |> map trim
      |> filter (rule: rule != "")
      |> map (ban: "iptables -I INPUT -s ${ban} -j REJECT")
      |> concatStringsSep "\n"
    }
  '';
}
