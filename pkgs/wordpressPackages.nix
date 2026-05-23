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
      version = "6.1.6";
      id = "contact-form-7";
      hash = "sha256-5s5y2+NveHIrLVhZmS9sPvYnCxFd+/ggbqq2nyusg3E=";
    };
    generic-oidc = mkWpPlugin {
      pname = "wp-generic-oidc";
      version = "3.11.3";
      id = "daggerhart-openid-connect-generic";
      hash = "sha256-/mqGWQz1lHsnA2dpQEZQVCWmqFSmDslFd4rzeEC4PA8=";
    };
    gutenberg = mkWpPlugin {
      pname = "gutenberg";
      version = "23.2.2";
      id = "gutenberg";
      hash = "sha256-jhuFCwuxwCrYgEv5Z5Ji06XcDwLaO1repGemZ7254XA=";
    };
    gutenberg-carousel = mkWpPlugin {
      pname = "wp-gutenberg-carousel";
      version = "2.1.3";
      id = "carousel-block";
      hash = "sha256-BOoTzNm0P4ykvBGmmAvDO46Buyqv5+Xlv+hCrPn0gXg=";
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
  lang =
    {
      lang,
      version,
      hash,
      ...
    }:
    stdenv.mkDerivation {
      name = "wp-language-nl";
      inherit version;

      src = fetchzip {
        url = "https://nl.wordpress.org/wordpress-${version}-${lang}.zip";
        name = "wp-${version}-language-nl";
        inherit hash;
      };

      installPhase = "mkdir -p $out; cp -r ./wp-content/languages/* $out/";
    };
}
