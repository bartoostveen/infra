{
  imports = [
    ./bart-pc.hardware.nix

    # keep-sorted start
    ../modules/infra/backup
    ../modules/infra/forgejo-actions.nix
    # ../modules/infra/hydra/builder.nix
    # keep-sorted end

    ../modules/gitlab-runner.nix
    ../modules/wireguard.nix

    ../modules/desktop/users/bart.nix

    # keep-sorted start
    ../modules/desktop/android.nix
    ../modules/desktop/audio.nix
    ../modules/desktop/bluetooth.nix
    ../modules/desktop/common.nix
    ../modules/desktop/fonts.nix
    ../modules/desktop/i18n.nix
    ../modules/desktop/kde.nix
    ../modules/desktop/kvm.nix
    ../modules/desktop/network-profiles.nix
    ../modules/desktop/networking.nix
    ../modules/desktop/nvidia.nix
    ../modules/desktop/obs-studio.nix
    ../modules/desktop/podman.nix
    ../modules/desktop/printing.nix
    ../modules/desktop/sudo.nix
    # keep-sorted end
  ];

  nix.settings = {
    system-features = [ "uid-range" ];
    auto-allocate-uids = true;
    extra-experimental-features = [
      "cgroups"
      "auto-allocate-uids"
    ];
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.loader.grub =
    let
      gfxmode = "1920x1080-75";
    in
    {
      device = "/dev/nvme0n1";
      gfxmodeEfi = gfxmode;
      gfxmodeBios = gfxmode;
    };

  boot.extraModprobeConfig = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';

  programs.steam.enable = true;

  infra.wireguard.enable = true;

  hardware.ckb-next.enable = true;

  infra.forgejo-actions = {
    enable = true;
    amount = 8;
    labels = [ "bigger-parallel:host" ];
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  system.stateVersion = "26.11";
}
