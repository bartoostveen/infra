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
        (nixpkgsPr 563545 "sha256-VHhp4aVpZ1aEOW6VRqqyLhWeKw07yrpA9UPm+yDfLpA=")
        (nixpkgsPr 554229 "sha256-8w+GC9jLQprATYVnVRaMyxXXKJ0AZUFJeIfCD+cdRYg=")
        (nixpkgsPr 564275 "sha256-OGVJ2wqaR231llXNqRaEhfqxqH7XhzrcF8xKuf1+928=")
        (nixpkgsPr 564339 "sha256-VNIo/a41SC7NyAc8OML11nPjRCceAWL7jhaUx8PMIDc=")
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
              # wordpress_7_1
              # wordpress
              # TODO: remove
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
