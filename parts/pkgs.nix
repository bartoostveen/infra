{
  inputs,
  lib,
  withSystem,
  ...
}:

let
  inherit (lib) flip;
in
{
  flake.pkgsForSystem = flip withSystem ({ pkgs, ... }: pkgs);

  perSystem =
    {
      inputs',
      system,
      pkgs,
      smallPkgs,
      deploy,
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
            patchFlags = [
              "-p1"
              "-N"
            ];
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
        (nixpkgsPr 576589 "sha256-QQhY0YEqbix/6mSyNPrOuJI/vvm3T6W9NykrDbO64p4=")
        ./revert-direnv-bump.patch
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
          "sable-1.22.11"
          "sable-unwrapped-1.22.11"
          "sable-desktop-1.22.11"
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
              ;

            inherit (inputs'.nix-auth.packages) nix-auth;
            inherit (inputs'.invoice.packages) invoice;

            _bartPackages = {
              suppressSystemWarning = true;
              prefix = "local";
            };

            # The design of deploy-rs' flake is truly wonderful, see also deploy.module.nix
            deploy-rs = deploy.deploy-rs // deploy;
          })
          inputs.bart-packages.overlays.default

          inputs.vert-nix.overlays.default
          inputs.copyparty.overlays.default
        ];
      };

      _module.args.smallPkgs = mkSimplePkgs inputs.nixos-small;
      _module.args.continuwuityPkgs = mkSimplePkgs inputs.nixpkgs-continuwuity;

      packages = {
        sshp = pkgs.writeShellApplication {
          name = "sshp";
          text = ''
            # shellcheck disable=SC2016
            nix eval --json \
              --apply 'builtins.mapAttrs (_: n: "''${n.profiles.system.sshUser}@''${n.hostname}")' \
              .#deploy.nodes 2>/dev/null \
              | jq -r 'to_entries | map(.value) | join("\n")' \
              | sshp "$@"
          '';
          runtimeInputs = [
            inputs.dtomvan-packages.packages.${pkgs.stdenv.hostPlatform.system}.sshp
            pkgs.jq
            pkgs.nix
          ];
        };
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
