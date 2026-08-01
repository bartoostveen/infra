{
  pkgs,
  continuwuityPkgs,
  ...
}:

{
  imports = [
    ../../matrix
  ];

  infra.matrix =
    let
      fqdn = "continuwuity-old.bartoostveen.nl";
    in
    {
      enable = true;
      alertmanager.enable = false;
      package = continuwuityPkgs.matrix-continuwuity.overrideAttrs {
        patches = [
          (pkgs.fetchpatch {
            url = "https://forgejo.ellis.link/continuwuation/continuwuity/pulls/2072.patch";
            hash = "sha256-F7hlmgHBvQ0z4bF5kOsGjjxR9FEg0QBDSYwrVFwwkxc=";
          })
        ];
      };
      inherit fqdn;
      domain = "server.${fqdn}";
    };

  services.matrix-continuwuity.settings.global.enable_legacy_invite_support = true;
}
