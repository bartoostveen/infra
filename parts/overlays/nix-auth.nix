{ inputs, ... }:

{
  flake.overlays.nix-auth = final: _prev: {
      inherit (inputs.nix-auth.packages.${final.stdenv.system}) nix-auth;
    };
}
