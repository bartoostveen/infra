{
  imports = [
    ../alacritty.nix
    ../common.nix
    ../copyparty-fuse.nix
    ../git
    ../gpg.nix
    ../jetbrains.nix
    ../plasma.nix
    ../tmux.nix
  ];

  common.gui = true;
}
