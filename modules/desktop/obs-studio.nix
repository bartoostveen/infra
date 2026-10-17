{
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkDefault
    ;
in
{
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = mkDefault false; # TODO: set to true again

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-tuna
    ];

    package = pkgs.obs-studio.override {
      cudaSupport = config.hardware.nvidia.enabled;
    };
  };
}
