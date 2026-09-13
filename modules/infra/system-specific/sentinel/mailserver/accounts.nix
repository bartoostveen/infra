{ config, ... }:

{
  mailserver.accounts = {
    "bart@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.bart-email-password-encrypted.path;
      aliases = [
        "postmaster@bartoostveen.nl"
        "security@bartoostveen.nl"
        "root@bartoostveen.nl"
        "anubis@bartoostveen.nl"
        "tcsbot@bartoostveen.nl"
        "dns@bartoostveen.nl"
        "matrix@bartoostveen.nl"
        "vimexx@bartoostveen.nl"

        "bart@boostveen.nl"

        "me@omeduostuurcentenneef.nl"
        "bart@omeduostuurcentenneef.nl"
        "postmaster@omeduostuurcentenneef.nl"
        "security@omeduostuurcentenneef.nl"
        "spam@omeduostuurcentenneef.nl"

        "postmaster@vitune.app"
        "security@vitune.app"
        "spam@vitune.app"
        "development@vitune.app"
      ];
    };
    "alerts@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.alertmanager-email-password-encrypted.path;
      sendOnly = true;
    };
    "auth@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.authentik-email-password-encrypted.path;
      sendOnly = true;
    };
    "git@bartoostveen.nl".hashedPasswordFile = config.sops.secrets.git-email-password-encrypted.path;
    "hydra@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.hydra-email-password-encrypted.path;
      sendOnly = true;
    };
    "vault@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.vaultwarden-email-password-encrypted.path;
      sendOnly = true;
    };
  };

  sops.secrets.alertmanager-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/alertmanager.enc.sentinel.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.authentik-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/auth.enc.sentinel.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.bart-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/bart.enc.sentinel.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.git-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/git.enc.sentinel.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.hydra-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/hydra.enc.sentinel.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.vaultwarden-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/vaultwarden.enc.sentinel.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };
}
