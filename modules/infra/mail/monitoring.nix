{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf;

  cfg = config.mailserver;
  metaCfg = config.infra.mail;

  rspamdMetricsPort = 32475;
in
{
  services.rspamd.workers.controller.bindSockets = [ "*:${toString rspamdMetricsPort}" ];
  services.prometheus.exporters = {
    dovecot.enable = true;
    postfix.enable = true;
  };
  infra.extraScrapeConfigs.rspamd.port = rspamdMetricsPort;

  services.prometheus.exporters.mail-tlsa-check = mkIf metaCfg.tlsa {
    enable = true;
    settings = {
      smtp.hostname = cfg.fqdn;
      imap.hostname = cfg.fqdn;
      tlsa.record = "_25._tcp.${cfg.fqdn}";
    };
  };

  infra.extraScrapeConfigs.tlsa = mkIf metaCfg.tlsa {
    port = config.services.prometheus.exporters.mail-tlsa-check.port;
  };
}
