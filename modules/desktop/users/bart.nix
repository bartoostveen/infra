{ config, ... }:

{
  nix.settings.trusted-users = [ "bart" ];

  users.users.bart = {
    isNormalUser = true;
    description = "Bart Oostveen";

    extraGroups = [
      "networkmanager"
      "wheel"
      "kvm"
      "adbusers"
      "docker"
      "audio"
      "bluetooth"
      "seat"
      "lp"
      "scanner"
      "libvirtd"
      "qemu-libvirtd"
      "wireshark"
      "dialout"
    ];

    hashedPasswordFile = config.sops.secrets.bart-password.path;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdc+Tbt0d+pHMYrDjrT3Ui09NV38T3bFWk/OMEL4Dp6 u0_a374@bart-phone"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4zwjOqILG37umIJNYYSMjveYzmwjOw/pTdfLbcsaSP bart@bart-laptop-new"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJ38XOn6VETxKPzT5SS1s3GexJmUV4P9aTNSe71DpFW bart@bart-pc"
    ];
  };

  infra.backup.jobs.state.paths = [ "/home/bart/.ssh" ];

  sops.secrets.bart-password = {
    sopsFile = ../../../secrets/non-infra/bart.pass.secret;
    neededForUsers = true;

    format = "binary";

    mode = "0600";
    owner = "bart";
    group = "bart";
  };
}
