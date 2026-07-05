{ lib, ... }:

{
  networking.nat.enable = true;
  networking.domain = "bartoostveen.nl";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall.extraCommands = ''
    iptables -I INPUT -s 77.160.138.6 -j REJECT
  '';
}
