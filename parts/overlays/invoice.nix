{ inputs, ... }:

{
  flake.overlays.invoice = final: _prev: {
    invoice = inputs.invoice.packages.${final.stdenv.system}.default;
  };
}
