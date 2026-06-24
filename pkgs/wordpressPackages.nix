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
    antispam-bee = mkWpPlugin {
      pname = "antispam-bee";
      version = "2.11.12";
      id = "antispam-bee";
      hash = "sha256-PsymEQIKhMNRS+Q/A/54G3vPlBwudlOVULKpH4q0fXg=";
    };
    contact-form-7 = mkWpPlugin {
      pname = "wp-contact-form-7";
      version = "6.1.6";
      id = "contact-form-7";
      hash = "sha256-5s5y2+NveHIrLVhZmS9sPvYnCxFd+/ggbqq2nyusg3E=";
    };
    indexnow = mkWpPlugin {
      pname = "indexnow";
      version = "1.0.3";
      id = "indexnow";
      url = "https://downloads.wordpress.org/plugin/indexnow.zip";
      hash = "sha256-iUqYrUUBSz2ytovpPWcukMWVR+IsYgZPe1zwI9Pgj0E=";
    };
    generic-oidc = mkWpPlugin {
      pname = "wp-generic-oidc";
      version = "3.11.3";
      id = "daggerhart-openid-connect-generic";
      hash = "sha256-/mqGWQz1lHsnA2dpQEZQVCWmqFSmDslFd4rzeEC4PA8=";
    };
    gutenberg = mkWpPlugin {
      pname = "gutenberg";
      version = "23.4.0";
      id = "gutenberg";
      hash = "sha256-y0cK0h1t27EHjt1v9/e0mm9Uva0HuW5ets9UKkgCHjM=";
    };
    gutenberg-carousel = mkWpPlugin {
      pname = "wp-gutenberg-carousel";
      version = "2.1.4";
      id = "carousel-block";
      hash = "sha256-nQWq5tm6CRuH/4mEVUH7QlmE9V4UPXwZs3UDStJx95s=";
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
