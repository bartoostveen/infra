{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../alacritty.nix
    ../copyparty-fuse.nix
    ../common.nix
    ../git
    ../gpg.nix
    ../jetbrains.nix
    ../plasma.nix
    ../tmux.nix
  ];

  common.gui = true;

  home = {
    packages = with pkgs; [
      wrk
      (inputs.prismlauncher-nixpkgs.legacyPackages.x86_64-linux.prismlauncher.override {
        additionalPrograms = [ ffmpeg ];
        jdks = [
          zulu8
          zulu17
          zulu
        ];
      })
    ];

    file = {
      ".gradle/gradle.properties".text = ''
        org.gradle.console=verbose
        org.gradle.daemon.idletimeout=3600000
      '';
    };
  };
}
