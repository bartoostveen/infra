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
    foldl'
    attrNames
    ;

  deployLibForSystem = system: withSystem system ({ deployLib, ... }: deployLib);

  inheritedGroups = foldl' (
    acc: group:
    foldl' (
      acc': node:
      acc'
      // {
        ${node} = (acc'.${node} or [ ]) ++ [ group ];
      }
    ) acc config.deployments.groups.${group}
  ) { } (attrNames config.deployments.groups);
in
{
  flake = {
    inherit deployLibForSystem;

    deploy.nodes =
      recursiveUpdate
        (genAttrs' config.deployments.home (
          {
            hostname,
            ip ? null,
            username,
            sshUser ? null,
            system,
            groups ? [ ],
            ...
          }:
          nameValuePair hostname {
            hostname = if ip != null then ip else hostname;

            profiles.${username} = {
              groups = groups ++ inheritedGroups.${hostname};
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
              groups ? [ ],
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
                groups = groups ++ inheritedGroups.${name};
                user = username;
                sshUser = if sshUser != null then sshUser else username;

                interactiveSudo = sshUser != username;

                path = (deployLibForSystem system).activate.nixos self.nixosConfigurations.${name};
              };
            }
          ) config.deployments.nixos
        );
  };

  perSystem =
    { pkgs, deployLib, ... }:

    {
      # Why did they only expose this through an overlay, this is so cursed :sob:
      _module.args.deployLib = (inputs.deploy-rs.overlays.default pkgs pkgs).deploy-rs.lib;
      checks = deployLib.deployChecks self.deploy;
    };
}
