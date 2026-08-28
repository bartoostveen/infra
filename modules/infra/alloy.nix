{
  inputs,
  config,
  wireguard,
  ...
}:

let
  endpoint = "http://${wireguard.primaryIpOf "sentinel"}:${toString inputs.self.nixosConfigurations.sentinel.config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
in
{
  services.alloy = {
    enable = true;
    extraFlags = [ "--disable-reporting" ];
  };
  environment.etc."alloy/config.alloy".text = ''
    loki.source.journal "journal" {
      max_age       = "24h0m0s"
      forward_to    = [loki.write.default.receiver]
      labels        = {
        host = "${config.networking.fqdn}",
        job  = "systemd_journal",
      }
      relabel_rules = loki.relabel.journal.rules
    }

    loki.relabel "journal" {
      forward_to = []
      
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
    }

    loki.write "default" {
      endpoint {
        url = "${endpoint}"
      }
      external_labels = {}
    }
  '';
}
