{
  lib,
  fetchFromForgejo,
  python314Packages,
  makeWrapper,
}:

let
  pythonPackages = python314Packages;
in
pythonPackages.buildPythonApplication (_finalAttrs: {
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

  patches = [
    ./0001-feat-support-port-environment-variable.patch
  ];

  postPatch = ''
    sed -i '1i #!${lib.getExe pythonPackages.python}' exporter.py
  '';

  dependencies = with pythonPackages; [
    requests
    prometheus-client
    flask
    gunicorn
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp exporter.py $out/bin/maubot-exporter
    chmod +x $out/bin/maubot-exporter
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
