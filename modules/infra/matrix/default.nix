{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    # keep-sorted start
    mkEnableOption
    mkOption
    mkPackageOption
    types
    # keep-sorted end
    ;

  inherit (types) listOf str bool;
in
{
  imports = [
    ./alertmanager.nix
    ./call.nix
    ./cinny.nix
    ./continuwuity.nix
    ./discord.nix
    ./element.nix
    ./livekit.nix
    ./signal.nix
    ./telegram.nix
  ];

  options.infra.matrix = {
    enable = mkEnableOption "Continuwuity with Livekit, Cinny and Element Call";
    package = mkPackageOption pkgs "matrix-continuwuity" { };
    fqdn = mkOption {
      description = "Full home server name";
      type = str;
      default = "example.com";
    };
    domain = mkOption {
      description = "Domain to proxy continuwuity to";
      type = str;
      default = "matrix.example.com";
    };
    livekit = {
      enable = mkEnableOption "Livekit/Matrix RTC";
      domain = mkOption {
        description = "Domain to host the livekit/lk-jwt-service/turn instance";
        type = str;
        default = "lk.example.com";
      };
    };
    element = {
      enable = mkEnableOption "Element web client";
      package = mkPackageOption pkgs "element-web" { };
      domain = mkOption {
        description = "Domain to host the Element web client";
        type = str;
        default = "element.example.com";
      };
    };
    call = {
      enable = mkEnableOption "Element Call";
      package = mkPackageOption pkgs "element-call" { };
      domain = mkOption {
        description = "Element call domain";
        type = str;
        default = "call.example.com";
      };
    };
    cinny = {
      enable = mkEnableOption "Cinny";
      package = mkPackageOption pkgs "cinny" { };
      replaceContinuwuity = mkOption {
        description = "Whether to replace c10y's 'welcome to continuwuity' with Cinny";
        type = bool;
        default = true;
        example = false;
      };
      domains = mkOption {
        description = "Domains to host a Cinny instance on";
        type = listOf str;
      };
    };
  };
}
