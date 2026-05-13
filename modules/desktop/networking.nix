{ pkgs, ... }:

{
  networking.domain = "device.bartoostveen.nl";

  networking.networkmanager.enable = true;

  programs.openvpn3.enable = true;
  networking.firewall.checkReversePath = "loose";
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  environment.systemPackages = with pkgs; [ eduvpn-client ];
}
