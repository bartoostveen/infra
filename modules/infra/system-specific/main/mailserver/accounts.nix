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
    "git@bartoostveen.nl" = {
      hashedPasswordFile = config.sops.secrets.git-email-password-encrypted.path;
      sendOnly = true;
    };
  };

  sops.secrets.alertmanager-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/email-passwords/alertmanager.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.authentik-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/email-passwords/auth.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.bart-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/email-passwords/bart.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };

  sops.secrets.git-email-password-encrypted = {
    format = "binary";
    sopsFile = ../../../../../secrets/email-passwords/git.enc.secret;

    restartUnits = [
      "postfix-setup.service"
      "dovecot.service"
    ];
  };
}
