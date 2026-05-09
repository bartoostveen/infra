{
  self,
  inputs,
  ...
}:

{
  perSystem =
    { system, pkgs, ... }:

    let
      mkSimplePkgs =
        p:
        import p {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
        config.permittedInsecurePackages = [
          "olm-3.2.16"
        ];

        overlays = [
          self.overlays.default
          self.overlays.nix-auth
          self.overlays.invoice
          self.overlays.fix-jabref

          inputs.copyparty.overlays.default
          # The design of deploy-rs' flake is truly wonderful, see also deploy.module.nix
          (_final: prev: {
            deploy-rs = prev.deploy-rs // {
              inherit (prev) deploy-rs;
            };
          })
        ];
      };

      _module.args.stablePkgs = mkSimplePkgs inputs.nixpkgs-stable;
      _module.args.continuwuityPkgs = mkSimplePkgs inputs.nixpkgs-continuwuity;

      # keep-sorted start
      packages.alertmanager-matrix = pkgs.callPackage ../pkgs/alertmanager-matrix/package.nix { };
      packages.autokuma = pkgs.callPackage ../pkgs/autokuma/package.nix { };
      packages.github-readme-stats = pkgs.callPackage ../pkgs/github-readme-stats/package.nix { };
      packages.ketesa = pkgs.callPackage ../pkgs/ketesa/package.nix { };
      packages.ketesa-unwrapped = pkgs.callPackage ../pkgs/ketesa/unwrapped.nix { };
      packages.librepods = pkgs.callPackage ../pkgs/librepods/package.nix { };
      packages.matrix-stickerbook = pkgs.callPackage ../pkgs/matrix-stickerbook/package.nix { };
      packages.mautrix-telegram-go = pkgs.callPackage ../pkgs/mautrix-telegram-go/package.nix { };
      packages.meshcore-gui = pkgs.callPackage ../pkgs/meshcore-gui/package.nix { };
      packages.meshcore-scan = pkgs.callPackage ../pkgs/meshcore-scan/package.nix { };
      packages.meshcoredecoder = pkgs.callPackage ../pkgs/meshcoredecoder/package.nix { };
      packages.roundcube-oidc = pkgs.callPackage ../pkgs/roundcube-oidc/package.nix { };
      packages.sable = pkgs.callPackage ../pkgs/sable/package.nix { };
      packages.sable-unwrapped = pkgs.callPackage ../pkgs/sable/unwrapped.nix { };
      packages.tilp = pkgs.callPackage ../pkgs/tilp/package.nix { };
      packages.venator = pkgs.callPackage ../pkgs/venator/package.nix { };
      packages.wp-oidc-roles = pkgs.callPackage ../pkgs/wp-oidc-roles/package.nix { };
      # keep-sorted end

      packages.sops-rotate =
        with pkgs;
        writeShellApplication {
          name = "sops-rotate";
          text = ''
            set -x
            find secrets/**/*.secret -exec sops rotate -i {} ";"
          '';
          runtimeInputs = [
            sops
            findutils
          ];
        };
    };
}
