{ stdenv, fetchzip, ... }:

let
  mkWpPlugin =
    {
      pname,
      id,
      version,
      hash,
      url ? "https://downloads.wordpress.org/plugin/${id}.${version}.zip",
    }:
    stdenv.mkDerivation (_finalAttrs: {
      inherit pname version;
      src = fetchzip {
        inherit url hash;
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    });
in
{
  plugins = {
    contact-form-7 = mkWpPlugin {
      pname = "wp-contact-form-7";
      version = "6.1.5";
      id = "contact-form-7";
      hash = "sha256-xdr6IswCSbHeVLWHAtZ1c/pfnzorfBCQ+lvMfMHTzfs=";
    };
    generic-oidc = mkWpPlugin {
      pname = "wp-generic-oidc";
      version = "3.11.3";
      id = "daggerhart-openid-connect-generic";
      hash = "sha256-/mqGWQz1lHsnA2dpQEZQVCWmqFSmDslFd4rzeEC4PA8=";
    };
    gutenberg = mkWpPlugin {
      pname = "gutenberg";
      version = "23.0.0";
      id = "gutenberg";
      hash = "sha256-htO2xO1gDvf1OYibOjzdjlMErZCULaEZXKWKdTnoUto=";
    };
    gutenberg-carousel = mkWpPlugin {
      pname = "wp-gutenberg-carousel";
      version = "2.1.1";
      id = "carousel-block";
      hash = "sha256-WKQ3aGqzcyWnI9XqNVKvd0RUOvg12sduNbJ6rKdCbQE=";
    };
    modify-profile-fields = mkWpPlugin {
      pname = "wp-modify-profile-fields";
      version = "1.1.0";
      id = "user-profile-dashboard-fields-control";
      hash = "sha256-f2lALAuTVTWmZB8z+A7fvv87vbwcwiASH7fsrK4WWGI=";
    };
    view-transitions = mkWpPlugin {
      pname = "wp-view-transitions";
      version = "1.2.0";
      id = "view-transitions";
      hash = "sha256-mHdek0LI51mfurpyXpM8QOK2E38PwoL8Ad3OQl9yW28=";
    };
  };
  lang.nl =
    version:
    stdenv.mkDerivation {
      name = "wp-language-nl";
      src = fetchzip {
        url = "https://nl.wordpress.org/wordpress-${version}-nl_NL.zip";
        name = "wp-${version}-language-nl";
        hash = "sha256-beU5XYpNX6ISD2y46q8r1Jy813V8zxWBzRK4V9d8L9M=";
      };
      installPhase = "mkdir -p $out; cp -r ./wp-content/languages/* $out/";
    };
}
