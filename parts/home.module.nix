{
  inputs,
  withSystem,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    genAttrs'
    nameValuePair
    mkOption
    types
    ;

  inherit (types)
    str
    nullOr
    submodule
    listOf
    ;
in
{
  options.deployments.home = mkOption {
    description = "The Home Manager configurations for this flake.";
    type = listOf (submodule {
      options = {
        username = mkOption {
          description = "Username to deploy the Home Manager configuration to";
          type = str;
        };
        sshUser = mkOption {
          description = "Username to deploy the Home Manager configuration from, defaults to username";
          type = nullOr str;
          default = null;
        };
        hostname = mkOption {
          description = "Hostname to deploy the Home Manager configuration to";
          type = str;
        };
        ip = mkOption {
          description = "IP address to deploy the Home Manager configuration to, defaults to hostname";
          type = nullOr str;
          default = null;
        };
        system = mkOption {
          description = "The host architecture";
          type = str;
          default = "x86_64-linux";
        };
      };
    });
  };

  config.flake.homeConfigurations = genAttrs' config.deployments.home (
    {
      username,
      hostname,
      system,
      ...
    }:

    withSystem system (
      { pkgs, ... }:

      nameValuePair "${username}@${hostname}" (
        inputs.home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = { inherit inputs; };

          inherit pkgs;

          modules = [
            ../home/${"${username}@${hostname}"}/home.nix
            {
              home = {
                inherit username;
                homeDirectory = "/home/${username}";
              };
            }
          ];
        }
      )
    )
  );
}
