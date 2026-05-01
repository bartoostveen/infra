{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (types) attrsOf attrs;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.srvos.nixosModules.mixins-terminfo
  ];

  options.infra = {
    extraScrapeConfigs = mkOption {
      description = "List of targets that can be monitored by Prometheus on this host";
      type = attrsOf attrs;
      default = { };
    };
  };

  config = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];

    nix.channel.enable = lib.mkForce false;
    nix.gc.automatic = lib.mkForce false;

    nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    nixpkgs.hostPlatform.system = "x86_64-linux";

    boot.loader.grub = {
      enable = true;

      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    networking.useNetworkd = lib.mkForce true;
    networking.firewall.enable = lib.mkForce true;

    services.dbus.implementation = "dbus";

    services.openssh.enable = lib.mkDefault true;

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdc+Tbt0d+pHMYrDjrT3Ui09NV38T3bFWk/OMEL4Dp6 u0_a374@bart-phone"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJ38XOn6VETxKPzT5SS1s3GexJmUV4P9aTNSe71DpFW bart@bart-pc"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4zwjOqILG37umIJNYYSMjveYzmwjOw/pTdfLbcsaSP bart@bart-laptop-new"
    ];

    services.redis.package = lib.mkDefault pkgs.valkey;

    programs.nh = {
      enable = lib.mkDefault true;
      clean = {
        enable = true;
        extraArgs = "--keep 3 --optimise";
        dates = "weekly";
      };
    };

    services.postgresql = {
      authentication = ''
        # type	database	user	origin-address	auth-method
        local	all		all			trust
        host	all		all	127.0.0.1/32	trust
        host	all		all	::1/128		trust
      '';
      identMap = ''
        # arbitraryMapName	systemUser	DBUser
        superuser_map		root		postgres
        superuser_map		postgres  	postgres

        # Let other names login as themselves
        superuser_map		/^(.*)$		\1
      '';
    };

    environment = {
      systemPackages = with pkgs; [
        curl
        wget
      ];
      variables.NH_SHOW_ACTIVATION_LOGS = 1;
    };
  };
}
