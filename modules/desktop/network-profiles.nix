{ config, inputs, ... }:

{
  imports = [
    "${inputs.wireless-profiles}/profiles.nix"
  ];

  networking.networkmanager.ensureProfiles.environmentFiles = [
    config.sops.secrets.nm-env.path
  ];

  sops.secrets.nm-env = {
    owner = "root";
    group = "root";
    mode = "0600";

    sopsFile = ../../secrets/non-infra/nm-env.secret;
    format = "binary";
  };
}
