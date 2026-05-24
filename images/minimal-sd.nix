{
  lib,
  pkgs,
  ...
}:

# Small experiment to create a very small NixOS image that is less brak than UTs pearl vm thingy

{
  imports = [
    ./minimal-sd.hardware.nix
  ];

  boot.loader.grub = {
    enable = true;
    devices = [ "nodev" ];
    efiSupport = true;
  };

  nix.channel.enable = lib.mkForce false;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = "vm";
  };
  services.displayManager.sddm.enable = true;

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  users.users.vm = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "wireshark"
      "networkmanager"
      "seat"
    ];
    hashedPassword = "$y$j9T$qb381.vDe3NbC2o9CJDxa.$vbvi8oPqkV49kmCuluAgzUGLrY9mfOjtP3LnBfp1ui0";
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  system.stateVersion = "26.11";
}
