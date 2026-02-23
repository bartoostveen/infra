{
  inputs,
  lib,
  withSystem,
  config,
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
          arch = mkOption {
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

  # TODO: clean this shit up wtf
  config.flake.nixosConfigurations =
    (mapAttrs (
      name:
      {
        arch,
        ...
      }@c:

      let
        hostname = if c.hostname != null then c.hostname else name;
      in
      withSystem arch (
        {
          pkgs,
          stablePkgs,
          personalPkgs,
          ...
        }:

        inputs.nixpkgs.lib.nixosSystem {
          inherit pkgs;

          specialArgs = { inherit inputs stablePkgs personalPkgs; };

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
          stablePkgs,
          ...
        }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit pkgs;
          specialArgs = { inherit inputs stablePkgs; };
          modules = [ ../images/${name}.nix ];
        }
      )
    ) config.deployments.extraNixOSConfigurations;
}
