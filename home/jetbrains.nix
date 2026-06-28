{ pkgs, ... }:

# HOW TO SWITCH TO X11/XWAYLAND WHEN JETBRAINS FUCKS UP WAYLAND
# Add `-Dawt.toolkit.name=XToolkit` to idea64.vmoptions (or another IDEs equivalent)

{
  home.packages = with pkgs; [
    jetbrains-toolbox
    jetbrains.idea
    jetbrains.gateway
    jetbrains.pycharm
    jetbrains.clion
  ];
}
