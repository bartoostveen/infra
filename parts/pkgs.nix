{
  self,
  inputs,
  ...
}:

{
  perSystem =
    {
      system,
      pkgs,
      smallPkgs,
      ...
    }:

    let
      mkSimplePkgs =
        p:
        import p {
          inherit system;
          config.allowUnfree = true;
        };

      wordpressPackages = pkgs.callPackage ../pkgs/wordpressPackages.nix { };
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
          (_final: prev: {
            local = {
              inherit wordpressPackages;
            }
            // prev.local;
          })

          self.overlays.nix-auth
          self.overlays.invoice
          self.overlays.fix-jabref

          (_final: _prev: {
            inherit (smallPkgs)
              apacheHttpd
              mariadb
              nginx
              openssh
              php
              ;
          })

          inputs.copyparty.overlays.default
          # The design of deploy-rs' flake is truly wonderful, see also deploy.module.nix
          (_final: prev: {
            deploy-rs = prev.deploy-rs // {
              inherit (prev) deploy-rs;
            };
          })
        ];
      };

      _module.args.smallPkgs = mkSimplePkgs inputs.nixos-small;
      _module.args.stablePkgs = mkSimplePkgs inputs.nixpkgs-stable;
      _module.args.continuwuityPkgs = mkSimplePkgs inputs.nixpkgs-continuwuity;

      packages = {
        # keep-sorted start
        alertmanager-matrix = pkgs.callPackage ../pkgs/alertmanager-matrix/package.nix { };
        autokuma = pkgs.callPackage ../pkgs/autokuma/package.nix { };
        github-readme-stats = pkgs.callPackage ../pkgs/github-readme-stats/package.nix { };
        ketesa = pkgs.callPackage ../pkgs/ketesa/package.nix { };
        ketesa-unwrapped = pkgs.callPackage ../pkgs/ketesa/unwrapped.nix { };
        librepods = pkgs.callPackage ../pkgs/librepods/package.nix { };
        mautrix-telegram-go = pkgs.callPackage ../pkgs/mautrix-telegram-go/package.nix { };
        meshcore-gui = pkgs.callPackage ../pkgs/meshcore-gui/package.nix { };
        meshcore-scan = pkgs.callPackage ../pkgs/meshcore-scan/package.nix { };
        meshcoredecoder = pkgs.callPackage ../pkgs/meshcoredecoder/package.nix { };
        roundcube-oidc = pkgs.callPackage ../pkgs/roundcube-oidc/package.nix { };
        sable = pkgs.callPackage ../pkgs/sable/package.nix { };
        sable-unwrapped = pkgs.callPackage ../pkgs/sable/unwrapped.nix { };
        tilp = pkgs.callPackage ../pkgs/tilp/package.nix { };
        venator = pkgs.callPackage ../pkgs/venator/package.nix { };
        wp-oidc-roles = pkgs.callPackage ../pkgs/wp-oidc-roles/package.nix { };
        # keep-sorted end

        sops-rotate =
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
      }
      // wordpressPackages.plugins;
    };
}
