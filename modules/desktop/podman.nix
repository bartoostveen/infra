{
  pkgs,
  config,
  ...
}:

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

  networking.firewall.interfaces."podman${if config.networking.nftables.enable then "*" else "+"}" = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };

  environment.systemPackages = with pkgs; [
    distrobox
    boxbuddy
    podman-compose
  ];
}
