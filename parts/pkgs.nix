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
      ...
    }:

    let
      mkSimplePkgs =
        p:
        import p {
          inherit system;
          config.allowUnfree = true;
        };

      patchInput =
        pkgs: patches: src:
        if patches == [ ] then
          src
        else
          pkgs.applyPatches {
            name = "source";
            inherit src patches;
          };

      patchFetchers = rec {
        ghPr =
          owner: repo: id: hash:
          smallPkgs.fetchurl {
            url = "https://github.com/${owner}/${repo}/pull/${toString id}.diff?full_index=1";
            inherit hash;
          };
        nixpkgsPr = ghPr "NixOS" "nixpkgs";
      };

      nixpkgsPatches = with patchFetchers; [
      ];

      patchedNixpkgs = patchInput smallPkgs nixpkgsPatches inputs.nixpkgs;
    in
    {
      _module.args.pkgs = import patchedNixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
        config.permittedInsecurePackages = [
          "olm-3.2.16"
        ];

        overlays = [
          (_: _: {
            inherit (smallPkgs)
              roundcube
              php82
              php82Packages
              php83
              php83Packages
              php84
              php84Packages
              php85
              php85Packages
              wordpress_7_0
              wordpress
              ;
          })

          self.overlays.nix-auth
          self.overlays.invoice

          (_: _: {
            _bartPackages = {
              suppressSystemWarning = true;
              prefix = "local";
            };
          })
          inputs.bart-packages.overlays.default

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

      _module.args.smallPkgs = mkSimplePkgs inputs.nixos-small;
      _module.args.continuwuityPkgs = mkSimplePkgs inputs.nixpkgs-continuwuity;

      packages = {
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
      };
    };
}
