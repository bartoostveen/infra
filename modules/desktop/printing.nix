{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    browsed.enable = true;
    defaultShared = true;
    openFirewall = true;
    cups-pdf.enable = true;
  };

  services.system-config-printer.enable = true;
  programs.system-config-printer.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    nssmdnsFull = true;
    openFirewall = true;
    settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;
    };
  };

  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
      ipp-usb
    ];
  };

  environment.systemPackages = with pkgs; [
    kdePackages.skanpage
  ];
}
