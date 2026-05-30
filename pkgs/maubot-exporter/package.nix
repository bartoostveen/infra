{
  lib,
  fetchFromForgejo,
  python314Packages,
  stdenv,
  makeWrapper,
}:

stdenv.mkDerivation (_finalAttrs: {
  pname = "maubot-exporter";
  version = "0-unstable-2026-05-30";

  pyproject = false;

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromForgejo {
    domain = "git.kurocon.nl";
    owner = "kuronet";
    repo = "maubot-exporter";
    rev = "461f80cb6b5a69cfa76c38f2b0c014d87978facb";
    hash = "sha256-wrmy1z443zx6CogX5eLiRL7bBm96XkGM/IvWYkcEyBc=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase =
    let
      pythonEnv = python314Packages.python.withPackages (
        ps: with ps; [
          flask
          gunicorn
          requests
          prometheus-client
        ]
      );
    in
    ''
      mkdir -p $out/libexec
      cp exporter.py $out/libexec/

      makeWrapper ${lib.getExe' pythonEnv "gunicorn"} $out/bin/maubot-exporter \
        --add-flags "--chdir $out/libexec exporter:app"
    '';

  meta = {
    description = "Simple metrics exporter for maubot";
    homepage = "https://git.kurocon.nl/kuronet/maubot-exporter";
    license = lib.licenses.unfree; # FIXME: no license exists
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "maubot-exporter";
    platforms = lib.platforms.all;
  };
})
