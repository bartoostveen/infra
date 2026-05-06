{
  pkgs,
  config,
  lib,
  ...
}:

{
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = lib.mkDefault true;

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-tuna
    ];

    package = pkgs.obs-studio.override {
      cudaSupport = config.hardware.nvidia.enabled;
    };
  };
}
