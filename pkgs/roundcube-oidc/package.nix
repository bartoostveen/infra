{
  lib,
  fetchFromGitHub,
  php,
  writeText,
  runCommand,
  configText ? "",
}:

let
  config = writeText "roundcube-oidc-config.php" configText;
  configChecked = runCommand "roundcube-oidc-config-checked" { } ''
    ${lib.getExe php} -l ${config}
    cp ${config} $out
  '';
in
php.buildComposerProject2 (_finalAttrs: {
  pname = "roundcube-oidc";
  version = "1.2.9";

  src = fetchFromGitHub {
    owner = "bartoostveen";
    repo = "roundcube-oidc";
    rev = "ed64ff998624b2e482a59c12b2870a74b2890cdd";
    hash = "sha256-ySgYNuiO+9X5+DcD9ZiG/GEe2UssrQoxTzlDZBqeox8=";
  };

  vendorHash = "sha256-n6xV5LIAyquQr1HsPJa5j/Mb9OVUW+101+hvpFbffO8=";
  composerStrictValidation = false;

  installPhase = ''
    mkdir -p $out/plugins/roundcube_oidc
    cp -R * $out/plugins/roundcube_oidc/
    cp ${configChecked} $out/plugins/roundcube_oidc/config.inc.php
  '';

  meta = {
    description = "OpenID Connect authentication plugin for Roundcube";
    homepage = "https://github.com/pulsejet/roundcube-oidc";
    license = lib.licenses.mit;
    mainProgram = "roundcube-oidc";
    platforms = lib.platforms.all;
  };
})
