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
  };

  sops.secrets.alertmanager-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/alertmanager.enc.bart-server.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.authentik-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/auth.enc.bart-server.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.bart-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/bart.enc.bart-server.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.git-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/mail/passwords/git.enc.bart-server.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };
}
