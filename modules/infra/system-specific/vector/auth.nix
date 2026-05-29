{ config, ... }:

{
  imports = [
    ../../authentik.nix
  ];

  infra.authentik = {
    enable = true;
    enablePrometheus = true;
    environmentFile = config.sops.secrets.authentik-env.path;
    domain = "auth.popkoorklankkleur.nl";
  };

  sops.secrets.authentik-env = {
    format = "binary";
    sopsFile = ../../../../secrets/authentik.env.vector.secret;

    owner = "authentik";
    group = "authentik";
    mode = "0660";
    restartUnits = [
      "authentik.service"
      "authentik-worker.service"
      "authentik-ldap.service"
    ];
  };

  sops.secrets.ldap-bind-password = {
    format = "binary";
    sopsFile = ../../../../secrets/ldap-bind-password.vector.secret;
    restartUnits = [
      "authentik.service"
      "authentik-worker.service"
      "authentik-ldap.service"
      "dovecot.service"
      "rspamd.service"
      "postfix.service"
    ];
  };
}
