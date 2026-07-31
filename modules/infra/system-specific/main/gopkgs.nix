{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  gitDomain = config.services.forgejo.settings.server.DOMAIN;
  goDomain = "go.bartoostveen.nl";
  port = 21434;

  inherit (lib)
    nameValuePair
    genAttrs'
    ;
in
{
  imports = [ inputs.bart-packages.nixosModules.timedout-registry ];

  services.timedout-registry = {
    enable = true;
    package = pkgs.local.timedout-registry;
    settings.listen = "127.0.0.1:${toString port}";
    entries =
      genAttrs'
        [
          # keep-sorted start
          "bulkmailer"
          "cpanel-matrix"
          "invoice"
          "meowbot"
          "nix-oci-lock"
          # keep-sorted end
        ]
        (
          mod:
          nameValuePair mod {
            import_path = "${goDomain}/${mod}";
            repo_url = "https://${gitDomain}/bart/${mod}";
          }
        );
  };

  services.nginx.virtualHosts.${goDomain} = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}

# {
#   bulkmailer = {
#     import_path = "go.bartoostveen.nl/bulkmailer";
#     repo_url = "https://git.bartoostveen.nl/bart/bulkmailer";
#   };
#   cpanel-matrix = {
#     import_path = "go.bartoostveen.nl/cpanel-matrix";
#     repo_url = "https://git.bartoostveen.nl/bart/cpanel-matrix";
#   };
#   invoice = {
#     import_path = "go.bartoostveen.nl/invoice";
#     repo_url = "https://git.bartoostveen.nl/bart/invoice";
#   };
#   meowbot = {
#     import_path = "go.bartoostveen.nl/meowbot";
#     repo_url = "https://git.bartoostveen.nl/bart/meowbot";
#   };
#   nix-oci-lock = {
#     import_path = "go.bartoostveen.nl/nix-oci-lock";
#     repo_url = "https://git.bartoostveen.nl/bart/nix-oci-lock";
#   };
# }
