{
  pkgs,
  lib,
  inputs,
  smallPkgs,
  ...
}:

let
  inherit (lib) makeLibraryPath;
in
{
  imports = [
    inputs.nix-index-database.nixosModules.default
  ];

  boot.loader.grub = {
    enable = true;
    useOSProber = true;
  };

  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = with pkgs; [
      nixos-bgrt-plymouth
    ];
  };

  boot.kernelPackages = smallPkgs.linuxKernel.packages.linux_7_1;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];
  nix.channel.enable = lib.mkForce false;

  services.resolved.enable = lib.mkDefault true;
  services.kresd.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    # keep-sorted start
    age
    attic-client
    copyparty
    curl
    deploy-rs
    file
    git
    nil
    nix-auth
    nix-inspect
    nix-output-monitor
    nixd
    nixfmt
    sops
    wget
    # keep-sorted end
    (writeShellApplication {
      name = "minikube";
      runtimeEnv = makeLibraryPath [ libvirt ];
      runtimeInputs = [
        libvirt
        minikube
      ];
      text = ''
        minikube "$@"
      '';
    })
  ];

  programs.nix-index-database.comma.enable = lib.mkDefault true;

  services.dbus.implementation = "dbus";

  programs.nh = {
    enable = lib.mkDefault true;
    clean = {
      enable = true;
      extraArgs = "--keep 2 --keep-since 2d";
      dates = "monthly";
    };
  };

  programs.gnupg.agent = {
    enable = lib.mkDefault true;
    enableSSHSupport = true;
  };

  programs.nano = {
    enable = lib.mkDefault true;
    nanorc = ''
      set historylog
      set multibuffer
      set positionlog
      set locking

      set tabsize 4
      set tabstospaces

      set guidestripe 80
      set constantshow
      set linenumbers
      set mouse
      set indicator

      set afterends
      set zap
      set jumpyscrolling
      set smarthome

      set trimblanks
      set colonparsing

      set atblanks
      set softwrap

      extendsyntax nix formatter ${pkgs.nixfmt}
    '';
  };

  programs.ente-auth.enable = true;

  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      UseDns = true;
      PasswordAuthentication = false;
      X11Forwarding = true;
    };
  };

  nix = {
    daemonIOSchedClass = lib.mkDefault "idle";
    daemonCPUSchedPolicy = lib.mkDefault "idle";
  };

  systemd.services.nix-daemon.serviceConfig.Slice = "-.slice";
  environment.variables = {
    NIX_REMOTE = "daemon";
    NH_SHOW_ACTIVATION_LOGS = 1;
  };

  services.libinput.enable = lib.mkForce true;
  services.flatpak.enable = lib.mkDefault true;
}
