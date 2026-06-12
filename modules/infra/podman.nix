{ pkgs, ... }:

{
  virtualisation = {
    containers.enable = true;
    oci-containers.backend = "podman";

    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  infra.backup.jobs.state.paths = [ "/var/lib/containers/storage" ];

  environment.systemPackages = with pkgs; [
    dive
    podman-compose
  ];
}
