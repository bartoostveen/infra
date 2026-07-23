{
  inputs,
  lib,
  withSystem,
  config,
  wireguard,
  ...
}:

let
  inherit (lib)
    mkOption
    mapAttrs
    types
    ;

  inherit (types)
    attrsOf
    submodule
    str
    nullOr
    ;
in
{
  options.deployments = {
    nixos = mkOption {
      description = "Set of NixOS configurations for a given host";
      type = attrsOf (submodule {
        options = {
          hostname = mkOption {
            description = "The host name of the NixOS configuration, the attrset key by default";
            type = nullOr str;
            default = null;
          };
          ip = mkOption {
            description = "The IP address to deploy the NixOS configuration to, the hostname by default";
            type = nullOr str;
            default = null;
          };
          username = mkOption {
            description = "The user to deploy as";
            type = str;
            default = "root";
          };
          sshUser = mkOption {
            description = "The user to push the configuration from, defaults to root";
            type = nullOr str;
            default = "root";
          };
          system = mkOption {
            description = "The host architecture";
            type = str;
            default = "x86_64-linux";
          };
        };
      });
    };

    extraNixOSConfigurations = mkOption {
      description = "Additional NixOS configurations that should be exported in the `nixosConfigurations` flake output, but not deployed";
      type = attrsOf (submodule {
        options = {
          arch = mkOption {
            description = "The host architecture";
            type = str;
            default = "x86_64-linux";
          };
        };
      });
    };
  };

  config = {
    _module.args.wireguard = import ../modules/wireguard.meta.nix { inherit lib; };

    flake = {
      inherit wireguard;

      nixosConfigurations =
        (mapAttrs (
          name:
          { system, ... }@c:

          let
            hostname = if c.hostname != null then c.hostname else name;
          in
          withSystem system (
            {
              pkgs,
              smallPkgs,
              continuwuityPkgs,
              ...
            }:

            inputs.nixpkgs.lib.nixosSystem {
              inherit pkgs system;

              specialArgs = {
                inherit
                  inputs
                  smallPkgs
                  continuwuityPkgs
                  wireguard
                  ;
              };

              modules = [
                inputs.sops-nix.nixosModules.sops
                { networking.hostName = hostname; }
                ../machines/${hostname}.nix
              ];
            }
          )
        ) config.deployments.nixos)
        // mapAttrs (
          name:
          { arch, ... }:
          withSystem arch (
            {
              pkgs,
              ...
            }:
            inputs.nixpkgs.lib.nixosSystem {
              inherit pkgs;
              specialArgs = { inherit inputs; };
              modules = [ ../images/${name}.nix ];
            }
          )
        ) config.deployments.extraNixOSConfigurations;
    };
  };
}
