# Amazing de-shittifier for the deploy-rs flake

{
  self,
  inputs,
  lib,
  config,
  withSystem,
  ...
}:

let
  inherit (lib)
    mapAttrs
    recursiveUpdate
    genAttrs'
    nameValuePair
    ;

  deployLibForSystem = system: withSystem system ({ deployLib, ... }: deployLib);
in
{
  flake.deploy.nodes =
    recursiveUpdate
      (genAttrs' config.deployments.home (
        {
          hostname,
          ip ? null,
          username,
          sshUser ? null,
          system,
          ...
        }:
        nameValuePair hostname {
          hostname = if ip != null then ip else hostname;

          profiles.${username} = {
            user = username;
            sshUser = if sshUser != null then sshUser else username;

            interactiveSudo = sshUser != username;

            path =
              (deployLibForSystem system).activate.home-manager
                self.homeConfigurations."${username}@${hostname}";
          };
        }
      ))
      (
        mapAttrs (
          name:
          {
            ip ? null,
            hostname ? null,
            sshUser ? null,
            username,
            system,
            ...
          }:

          let
            h =
              if ip != null then
                ip
              else if hostname != null then
                hostname
              else
                name;
          in
          {
            hostname = h;

            profiles.system = {
              user = username;
              sshUser = if sshUser != null then sshUser else username;

              interactiveSudo = sshUser != username;

              path = (deployLibForSystem system).activate.nixos self.nixosConfigurations.${name};
            };
          }
        ) config.deployments.nixos
      );

  perSystem =
    { pkgs, deployLib, ... }:

    {
      # Why did they only expose this through an overlay, this is so cursed :sob:
      _module.args.deployLib = (inputs.deploy-rs.overlays.default pkgs pkgs).deploy-rs.lib;
      checks = deployLib.deployChecks self.deploy;
    };
}
