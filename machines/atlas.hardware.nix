{ lib, ... }:

{
  boot.kernelParams = [
    "console=ttyS1,115200n8"
    "console=tty0"
    "cma=320M"
  ];

  boot.initrd.kernelModules = [
    "vc4"
    "bcm2835_dma"
    "i2c_bcm2835"
  ];

  fileSystems."/var/lib/borg" = {
    device = "/dev/disk/by-uuid/a28033a5-dc12-4f5f-8260-f79076cae272";
    fsType = "ext4";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true";
      };
      Policy = {
        AutoEnable = "true";
      };
    };
  };

  networking.wireless.enable = lib.mkDefault true;

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.consoleLogLevel = lib.mkDefault 7;
  hardware.enableRedistributableFirmware = true;
  networking.useDHCP = lib.mkDefault true;
}
