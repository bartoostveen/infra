{
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "euro";
    };
  };

  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.kdeconnect.enable = true;
  programs.kclock.enable = true;
}
