{ lib, inputs, ... }:

let
  inherit (lib) concatStringsSep splitString;
  inherit (builtins) readFile;
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
      |> map (ban: "iptables -I INPUT -s ${ban} -j REJECT")
      |> concatStringsSep "\n"
    }
  '';
}
