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
        (nixpkgsPr 543298 "sha256-XkkdJeqL24Tt6leNpL9v8Y4qNT5+W7TXDREnDZZ2f/I=")
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
          (final: _prev: {
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

            # HACK: regression in latest NixOS Unstable, should investigate later
            # Reverts https://github.com/NixOS/nixpkgs/pull/541979
            # Overriding impossible because of nested overrides
            attic-client = final.callPackage (
              {
                lib,
                rustPlatform,
                fetchFromGitHub,
                nixVersions,
                nixosTests,
                boost,
                pkg-config,
                stdenv,
                installShellFiles,
                nix-update-script,
                crates ? [ "attic-client" ],
              }:

              let
                # Only the attic-client crate builds against the Nix C++ libs
                # This derivation is also used to build the server
                needNixInclude = lib.elem "attic-client" crates;
                nix = nixVersions.nix_2_34;
              in

              rustPlatform.buildRustPackage {
                pname = "attic";
                version = "0-unstable-2026-06-26";

                src = fetchFromGitHub {
                  owner = "zhaofengli";
                  repo = "attic";
                  rev = "b7c905657cb81b8ec9c26b0d9f53aa2e4f231810";
                  hash = "sha256-//gQFVLVFhwHyI9yrpPqX0MQJGYqS6nE/iLV872K+PU=";
                };

                nativeBuildInputs = [
                  pkg-config
                  installShellFiles
                ];

                buildInputs = lib.optional needNixInclude nix ++ [ boost ];

                cargoBuildFlags = lib.concatMapStrings (c: "-p ${c} ") crates;
                cargoHash = "sha256-fYWRlgP3uwntULe6o2MC1yB/ea2x+27m1Op7o2wUd+U=";

                env = {
                  ATTIC_DISTRIBUTOR = "nixpkgs";
                }
                // lib.optionalAttrs needNixInclude { NIX_INCLUDE_PATH = "${lib.getDev nix}/include"; };

                # Attic interacts with Nix directly and its tests require trusted-user access
                # to nix-daemon to import NARs, which is not possible in the build sandbox.
                doCheck = false;

                postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
                  if [[ -f $out/bin/attic ]]; then
                    installShellCompletion --cmd attic \
                      --bash <($out/bin/attic gen-completions bash) \
                      --zsh <($out/bin/attic gen-completions zsh) \
                      --fish <($out/bin/attic gen-completions fish)
                  fi
                '';

                passthru = {
                  tests = { inherit (nixosTests) atticd; };

                  updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
                };

                meta = {
                  description = "Multi-tenant Nix Binary Cache";
                  homepage = "https://github.com/zhaofengli/attic";
                  license = lib.licenses.asl20;
                  maintainers = with lib.maintainers; [
                    zhaofengli
                    aciceri
                    defelo
                  ];
                  platforms = lib.platforms.linux ++ lib.platforms.darwin;
                  mainProgram = "attic";
                };
              }
            ) { };
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
