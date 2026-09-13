{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mapAttrsToList
    ;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./sentinel.disk-config.nix

    inputs.nixos-facter-modules.nixosModules.facter

    inputs.srvos.nixosModules.server
    inputs.srvos.nixosModules.hardware-hetzner-online-amd

    ../modules/wireguard.nix

    # keep-sorted start
    ../modules/infra/alloy.nix
    ../modules/infra/system-specific/sentinel/attic.nix
    ../modules/infra/system-specific/sentinel/containers/tcs-bot.nix
    ../modules/infra/system-specific/sentinel/containers/web.nix
    ../modules/infra/system-specific/sentinel/forgejo.nix
    ../modules/infra/system-specific/sentinel/git-pages.nix
    ../modules/infra/system-specific/sentinel/gopkgs.nix
    ../modules/infra/system-specific/sentinel/ical-proxy.nix
    ../modules/infra/system-specific/sentinel/ircbounce.nix
    ../modules/infra/system-specific/sentinel/mailserver
    ../modules/infra/system-specific/sentinel/matrix.nix
    ../modules/infra/system-specific/sentinel/maubot.nix
    ../modules/infra/system-specific/sentinel/meowbot.nix
    ../modules/infra/system-specific/sentinel/monitoring.nix
    ../modules/infra/system-specific/sentinel/tascheduling-db.nix
    ../modules/infra/system-specific/sentinel/venator.nix
    ../modules/infra/system-specific/sentinel/wireguard.monitoring.nix
    # keep-sorted end

    # keep-sorted start
    ../modules/infra/alertmanager.nix
    ../modules/infra/anubis.nix
    ../modules/infra/authentik.nix
    ../modules/infra/autokuma-config.nix
    ../modules/infra/backup
    ../modules/infra/common.nix
    ../modules/infra/copyparty.nix
    ../modules/infra/dns.nix
    ../modules/infra/fail2ban.nix
    ../modules/infra/forgejo-actions.nix
    ../modules/infra/git.nix
    ../modules/infra/networking.nix
    ../modules/infra/nginx.extra.nix
    ../modules/infra/nginx.nix
    ../modules/infra/nix.nix
    ../modules/infra/podman.nix
    # keep-sorted end
  ];

  facter.reportPath = ./sentinel.json;
  systemd.network.networks."10-uplink".networkConfig.Address = "2a01:4f8:c2c:2f66::1/128";

  srvos.prometheus.ruleGroups.srvosAlerts.alertRules = {
    # keep-sorted start
    UnusualDiskReadLatency.enable = false;
    Uptime.enable = false;
    # keep-sorted end
  };

  infra.copyparty = {
    enable = true;
    acme = true;
  };

  infra.wireguard.enable = true;

  infra.authentik = {
    enable = true;
    enablePrometheus = true;
    environmentFile = config.sops.secrets.authentik-env.path;
  };

  infra.backup = {
    enableDefaults = true;
    postgres.enable = true;
    jobs.state.paths = config.infra.copyparty.volumes |> mapAttrsToList (_: v: v.path);
    jobs.state.exclude = [ "/root/private/fs/muziek/" ];
  };

  infra.forgejo-actions = {
    enable = true;
    labels = [ "gpg:host" ];
    systemdDependencies = [ "forgejo.service" ];
  };

  sops.secrets.authentik-env = {
    format = "binary";
    sopsFile = ../secrets/authentik.env.sentinel.secret;

    owner = "authentik";
    group = "authentik";
    mode = "0660";
    restartUnits = [
      "authentik.service"
      "authentik-worker.service"
      "authentik-ldap.service"
    ];
  };

  system.stateVersion = "26.11";
}
