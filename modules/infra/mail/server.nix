{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkForce
    mkIf
    concatStringsSep
    ;

  cfg = config.mailserver;
  metaCfg = config.infra.mail;
in
{
  mailserver = {
    enable = mkDefault true;
    fqdn = mkDefault "mx.${cfg.systemDomain}";
    x509.useACMEHost = mkDefault cfg.systemDomain;
    domains = mkDefault [ cfg.systemDomain ];

    dmarcReporting.enable = true;
    tlsrpt.enable = true;
    systemContact = mkDefault "postmaster@${cfg.systemDomain}";

    enableManageSieve = true;
    enableSubmission = true; # Enable StartTLS

    hierarchySeparator = "/"; # See: https://doc.dovecot.org/main/core/config/namespaces.html#namespaces

    fullTextSearch = {
      enable = true;
      autoIndex = true;
    };

    useUTF8FolderNames = mkForce true;

    stateVersion = mkDefault 5; # Only change this line after performing state migrations!
  };

  services.nginx.virtualHosts.${cfg.systemDomain} = {
    serverAliases = (lib.lists.remove cfg.systemDomain cfg.domains) ++ [ cfg.fqdn ];
    forceSSL = mkDefault true;
    enableACME = mkForce true;
  };

  # In order to support consistent DANE TLSA
  security.acme.certs."${cfg.systemDomain}".extraLegoRenewFlags = mkIf metaCfg.tlsa [
    "--reuse-key"
  ];

  services.postfix =
    let
      deniedRecipientsFileName = "denied_recipients_additional";
    in
    {
      mapFiles.${deniedRecipientsFileName} = builtins.toFile deniedRecipientsFileName (
        metaCfg.additionalDeniedRecipients
        |> map (n: "${n} REJECT This account cannot receive emails.")
        |> concatStringsSep "\n"
      );

      settings.main = {
        inet_protocols = mkForce "ipv4, ipv6";
        smtpd_recipient_restrictions = [
          "check_recipient_access hash:/var/lib/postfix/conf/${deniedRecipientsFileName}"
        ];
      };
    };

  infra.backup.jobs.state.paths = [ config.mailserver.storage.path ];
}
