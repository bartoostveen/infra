{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.common;
  inherit (builtins) fromJSON readFile;
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  options.common = {
    gui = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Whether to add gui packages";
    };
  };

  config = {
    nixpkgs.config.allowUnfree = true;

    home = {
      stateVersion = "26.05";

      sessionVariables = {
        EDITOR = "nano";
        SDL_VIDEODRIVER = "wayland";
      };

      shellAliases = {
        cat = "bat";
      };

      packages =
        with pkgs;
        [
          # keep-sorted start
          bat
          btop
          curl
          dust
          ffmpeg
          forgejo-cli
          gh
          glab
          gopass
          htop
          incus
          invoice
          jq
          meteor-git
          nano
          nix-init
          nurl
          ripgrep
          tomlq
          unzip
          wget
          zip
          # keep-sorted end
        ]
        ++ lib.optionals cfg.gui [
          # keep-sorted start
          discord
          kdePackages.kate
          kdePackages.krdc
          kdePackages.krfb
          libreoffice
          localsend
          mpv
          nerd-fonts.jetbrains-mono
          nextcloud-client
          pavucontrol
          pdfarranger
          pwvucontrol
          signal-desktop
          teams-for-linux
          telegram-desktop
          vlc
          wl-clipboard
          # keep-sorted end
        ];
    };

    xdg.configFile."google-chrome/NativeMessagingHosts" = lib.mkIf cfg.gui {
      source = "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts";
      recursive = true;
    };

    fonts.fontconfig.enable = true;

    programs.home-manager.enable = true;

    programs.oh-my-posh = {
      enable = lib.mkDefault true;
      enableBashIntegration = true;
      settings = fromJSON (readFile ./oh-my-posh.json);
    };

    programs.direnv = {
      enable = lib.mkDefault true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
      config.hide_env_diff = true;
    };

    services.nextcloud-client = {
      enable = lib.mkDefault cfg.gui;
      startInBackground = lib.mkDefault true;
    };

    programs.thunderbird = {
      enable = lib.mkDefault cfg.gui;
      settings."mail.openpgp.allow_external_gnupg" = true;
    };

    programs.google-chrome.enable = lib.mkDefault cfg.gui;
    programs.vscode.enable = lib.mkDefault cfg.gui;

    programs.yt-dlp = {
      enable = lib.mkDefault true;
      settings.sponsorblock-mark = "all,-preview";
    };

    programs.bash = {
      enable = lib.mkDefault true;
      enableCompletion = true;
      historyControl = [ "erasedups" ];
      sessionVariables.PROMPT_COMMAND = "history -a; history -n";
    };

    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };
}
