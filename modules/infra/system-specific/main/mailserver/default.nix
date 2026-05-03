{ config, ... }:

{
  imports = [
    ../../../mail
    ./accounts.nix
  ];

  mailserver = {
    systemDomain = "bartoostveen.nl";
    domains = [
      "bartoostveen.nl"
      "boostveen.nl"
      "vitune.app"
      "omeduostuurcentenneef.nl"
    ];
    stateVersion = 4;
  };

  services.roundcube = {
    enable = true;
    hostName = "webmail.bartoostveen.nl";
    extraConfig = ''
      $config['imap_host'] = "ssl://${config.mailserver.fqdn}:993";
      $config['imap_auth_type'] = 'LOGIN';
      $config['imap_delimiter'] = '/';
      $config['imap_conn_options'] = array(
          'ssl' => array(
              'verify_peer'  => false,
              'verify_peer_name' => false,
          ),
      );

      $config['smtp_host'] = "ssl://${config.mailserver.fqdn}:465";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
      $config['smtp_auth_type'] = 'LOGIN';
      $config['smtp_conn_options'] = array(
          'ssl' => array(
              'verify_peer'  => false,
              'verify_peer_name' => false,
          ),
      );
    '';
  };
}
