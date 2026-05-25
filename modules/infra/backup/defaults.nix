{
  config,
  lib,
  wireguard,
  ...
}:

let
  enable = config.infra.backup.enableDefaults;

  inherit (lib)
    mkEnableOption
    mkIf
    mkDefault
    ;
in
{
  options.infra.backup.enableDefaults = mkEnableOption "defaults";
  config = mkIf enable {
    infra.backup = {
      enable = mkDefault true;
      postgres.jobName = mkDefault "state";
      mysql.jobName = mkDefault "state";
      jobs.state.host = wireguard.primaryIpOf "atlas";
      defaults = {
        sshKeyFile = mkDefault config.sops.secrets.borg-ssh-key.path;
        secretKeyFile = mkDefault config.sops.secrets.borg-secret.path;
      };
    };

    sops.secrets.borg-ssh-key = mkDefault {
      format = "binary";
      sopsFile = ../../../secrets/borg/borg-id_ed25519.secret;
    };

    sops.secrets.borg-secret = mkDefault {
      format = "binary";
      sopsFile = ../../../secrets/borg/borg-key.secret;
    };
  };
}
