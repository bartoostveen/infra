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
    ./git.nix
    inputs.sops-nix.homeManagerModules.sops
    inputs.tailray.homeManagerModules.default
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
      stateVersion = "25.05";

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
          bat
          btop
          curl
          local.dawn
          dust
          ffmpeg
          forgejo-cli
          gh
          glab
          gopass
          inputs.licenseit.packages.${pkgs.stdenv.system}.default
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
        ]
        ++ lib.optionals cfg.gui [
          discord
          element-desktop
          kdePackages.kate
          keystore-explorer
          libreoffice
          localsend
          mpv
          nerd-fonts.jetbrains-mono
          obsidian
          pavucontrol
          pdfarranger
          signal-desktop
          teams-for-linux
          telegram-desktop
          thunderbird
          vlc
          wl-clipboard
        ];
    };

    xdg.configFile = {
      "gh-dash/config.yml".source = ./gh-dash.yml;
      "google-chrome/NativeMessagingHosts" = lib.mkIf cfg.gui {
        source = "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts";
        recursive = true;
      };
    };

    fonts.fontconfig.enable = true;

    services.tailray.enable = lib.mkDefault cfg.gui;
    systemd.user.services.tailray.Service.Environment = lib.optionals config.services.tailray.enable [
      "TAILRAY_ADMIN_URL=https://headplane.vitune.app/admin/login"
    ];

    programs.home-manager.enable = true;

    programs.oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      settings = fromJSON (readFile ./oh-my-posh.json);
    };

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
      config = {
        hide_env_diff = true;
      };
    };

    programs.google-chrome.enable = lib.mkDefault cfg.gui;
    programs.vscode.enable = lib.mkDefault cfg.gui;

    programs.yt-dlp = {
      enable = true;
      settings.sponsorblock-mark = "all,-preview";
    };

    programs.bash = {
      enable = true;
      enableCompletion = true;
      historyControl = [ "erasedups" ];
      sessionVariables.PROMPT_COMMAND = "history -a; history -n";
    };

    programs.delta.enable = true;
    git = {
      enable = true;
      gh.enable = true;

      user.email = "bart@bartoostveen.nl";
      user.name = "Bart Oostveen";

      key = "5963223E57296C53";
    };
    programs.git.includes = [
      {
        condition = "hasconfig:remote.*.url:git@gitlab.utwente.nl:*/**";
        contents.user = {
          email = "b.oostveen@student.utwente.nl";
          name = "Oostveen, B. (Bart, Student B-TCS)";
          signingKey = "FAD453F45800E974";
        };
      }
      {
        condition = "hasconfig:remote.*.url:git@gitlab.snt.utwente.nl:*/**";
        contents.user = {
          email = "oostveen@snt.utwente.nl";
          name = "Bart Oostveen";
          signingKey = "2D4FB795E873C2C3";
        };
      }
    ];

    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    dont-track-me.enable = true;
  };
}
