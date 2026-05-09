{
  pkgs,
  lib,
  continuwuityPkgs,
  ...
}:

let
  inherit (lib) range genAttrs' nameValuePair;

  fqdn = "bartoostveen.nl";
  cinnies = range 0 9;
in
{
  imports = [
    ../../matrix
  ];

  infra.matrix = {
    enable = true;
    package = continuwuityPkgs.matrix-continuwuity;
    inherit fqdn;
    domain = "matrix.${fqdn}";
    livekit = {
      enable = true;
      domain = "matrix-rtc.${fqdn}";
    };
    call = {
      enable = true;
      domain = "call.${fqdn}";
    };
    element = {
      enable = true;
      domain = "element.${fqdn}";
    };
    cinny = {
      enable = true;
      package = pkgs.local.sable.override {
        conf = {
          homeserverList = [
            fqdn
            "elisaado.com"
            "utwente.io"
            "matrix.org"
            "inter-actief.net"
          ];
          defaultHomeserver = 0;
          allowCustomHomeservers = true;
          featuredCommunities = { };
          hashRouter.enabled = true;
        };
      };
      domains = map (n: "cinny${toString n}.${fqdn}") cinnies;
    };
  };

  services.nginx.virtualHosts = genAttrs' cinnies (
    n:
    nameValuePair "cinny${toString n}.${fqdn}" {
      serverAliases = [ "sable${toString n}.${fqdn}" ];
    }
  );
}
