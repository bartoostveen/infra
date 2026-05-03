{ config, lib, ... }:

let
  inherit (lib)
    genAttrs
    mkIf
    genAttrs'
    attrNames
    nameValuePair
    ;

  cfg = config.mailserver;
  metaCfg = config.infra.mail;
in
{
  mailserver.dkim.domains = genAttrs cfg.domains (name: {
    selectors.mail.keyFile = config.sops.secrets."${name}.mail.key".path;
  });

  sops.secrets = mkIf (metaCfg.sops) (
    genAttrs' (attrNames cfg.dkim.domains) (
      name:
      nameValuePair "${name}.mail.key" {
        format = "binary";
        owner = "rspamd";
        group = "rspamd";
        mode = "0600";
        sopsFile = ../../../secrets/dkim/${name}.mail.private.secret;
        restartUnits = [ "rspamd.service" ];
      }
    )
  );
}
