{
  pkgs,
  config,
  ...
}:

{
  imports = [
    ./bart-laptop-new.hardware.nix

    ../modules/wireguard.nix

    ../modules/desktop/users/bart.nix

    ../modules/desktop/android.nix
    ../modules/desktop/audio.nix
    ../modules/desktop/bluetooth.nix
    ../modules/desktop/copyparty-fuse.nix
    ../modules/desktop/common.nix
    ../modules/desktop/fonts.nix
    ../modules/desktop/i18n.nix
    ../modules/desktop/kde.nix
    ../modules/desktop/kvm.nix
    ../modules/desktop/network-profiles.nix
    ../modules/desktop/networking.nix
    ../modules/desktop/podman.nix
    ../modules/desktop/printing.nix
    ../modules/desktop/sudo.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
    };
  };

  time.hardwareClockInLocalTime = true;
  boot.kernel.sysctl."vm.swappiness" = 0;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  environment.systemPackages = with pkgs; [
    kdePackages.krfb
    kdePackages.krdc
  ];

  networking.wireguard = {
    useNetworkd = true;
    interfaces.wg-snt = {
      ips = [
        "172.30.149.116/32"
        "fd0d:c7a1:e166:ca6c::116/128"
      ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets.wg-secret.path;
      peers = [
        {
          publicKey = "IlMJO6p4HoKhVMVcP+8BJNmPnYp6jnjHP0PxEmBCIis=";
          allowedIPs = [
            "172.30.149.0/24"
            # "130.89.0.0/16"
            "10.89.0.0/16"
            "2001:67c:2564::/48"
            "fd0d:c7a1:e166::/64"
          ];
          endpoint = "vpn2.snt.utwente.nl:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  sops.secrets.wg-secret = {
    format = "binary";
    sopsFile = ../secrets/wg-private.secret;
    reloadUnits = [ "systemd-networkd.service" ];
  };

  infra.wireguard.enable = true;

  programs.steam.enable = true;

  system.stateVersion = "26.05";
}
