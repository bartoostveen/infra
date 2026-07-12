{
  inputs,
  lib,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types) bool listOf str;
in
{

  imports = [
    inputs.nixos-mailserver.nixosModules.default
    # keep-sorted start
    ./autoconfig.nix
    ./bounce.nix
    ./dkim.nix
    ./monitoring.nix
    ./server.nix
    # keep-sorted end
  ];

  options.infra.mail = {
    autoconfig = mkOption {
      description = "Whether to enable autoconfig";
      type = bool;
      default = true;
      example = false;
    };
    sops = mkOption {
      description = "Whether to automatically import DKIM sops secrets from secrets/dkim";
      type = bool;
      default = true;
      example = false;
    };
    tlsa = mkOption {
      description = "Whether TLSA is enabled";
      type = bool;
      default = true;
      example = false;
    };
    additionalDeniedRecipients = mkOption {
      description = "list of additionally denied full addresses";
      type = listOf str;
      default = [ ];
    };
  };
}
