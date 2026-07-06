{
  self,
  inputs,
  ...
}:

{
  perSystem =
    {
      inputs',
      system,
      pkgs,
      smallPkgs,
      phpPkgs,
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
            inherit (smallPkgs) roundcube;
            local = {
              inherit wordpressPackages;
            }
            // prev.local;
            inherit (phpPkgs)
              php82
              php82Packages
              php83
              php83Packages
              php84
              php84Packages
              php85
              php85Packages
              ;
          })

          self.overlays.nix-auth
          self.overlays.invoice

          inputs.vert-nix.overlays.default
          inputs.copyparty.overlays.default
          # The design of deploy-rs' flake is truly wonderful, see also deploy.module.nix
          (_final: prev: {
            deploy-rs = prev.deploy-rs // {
              inherit (prev) deploy-rs;
            };
          })
        ];
      };

      _module.args.phpPkgs = mkSimplePkgs inputs.nixpkgs-php-security;
      _module.args.smallPkgs = mkSimplePkgs inputs.nixos-small;
      _module.args.continuwuityPkgs = mkSimplePkgs inputs.nixpkgs-continuwuity;

      packages = {
        # keep-sorted start
        alertmanager-matrix = pkgs.callPackage ../pkgs/alertmanager-matrix/package.nix { };
        autokuma = pkgs.callPackage ../pkgs/autokuma/package.nix { };
        github-readme-stats = pkgs.callPackage ../pkgs/github-readme-stats/package.nix { };
        librepods = pkgs.callPackage ../pkgs/librepods/package.nix { };
        maubot-exporter = pkgs.callPackage ../pkgs/maubot-exporter/package.nix { };
        mautrix-telegram-go = pkgs.callPackage ../pkgs/mautrix-telegram-go/package.nix { };
        meshcore-scan = pkgs.callPackage ../pkgs/meshcore-scan/package.nix { };
        meshcoredecoder = pkgs.callPackage ../pkgs/meshcoredecoder/package.nix { };
        sable = pkgs.callPackage ../pkgs/sable/package.nix { };
        sable-unwrapped = pkgs.callPackage ../pkgs/sable/unwrapped.nix { };
        tilp = pkgs.callPackage ../pkgs/tilp/package.nix { };
        venator = pkgs.callPackage ../pkgs/venator/package.nix { };
        wp-oidc-roles = pkgs.callPackage ../pkgs/wp-oidc-roles/package.nix { };
        # keep-sorted end

        inherit (inputs'.nix-oci-lock.packages) nix-oci-lock;

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

        yaml2nix =
          with pkgs;
          writeShellApplication {
            name = "yaml2nix";
            text = ''
              temp=$(mktemp)
              yq . "$1" > "$temp"
              nix \
                --extra-experimental-features 'nix-command' \
                eval --impure \
                --expr "builtins.fromJSON (builtins.readFile \"""$temp""\")" | nixfmt | bat -l nix
              rm "$temp"
            '';
            runtimeInputs = [
              yq
              nix
              nixfmt
              bat
            ];
          };
      }
      // wordpressPackages.plugins;
    };
}
