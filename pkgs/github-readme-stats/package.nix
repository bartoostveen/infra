{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_26,
}:

buildNpmPackage (finalAttrs: {
  pname = "github-readme-stats";
  version = "0-unstable-2026-05-19";

  src = fetchFromGitHub {
    owner = "bartoostveen";
    repo = "github-readme-stats";
    rev = "4072cfc0bb99ceed46814b05818138c01c8e8539";
    hash = "sha256-bOzOI3YSIqgQXahoXW65A5VL+29qmQ388VAuOqh3RJk=";
  };

  npmDepsHash = "sha256-oiB+OA6a/okbWezOODY8EpWPxy6BgnceoXQrOOIZUy4=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out/
    makeWrapper ${lib.getExe nodejs_26} $out/bin/${finalAttrs.pname} --append-flag "$out/express.js"
    runHook postInstall
  '';

  meta = {
    description = "Zap: Dynamically generated stats for your github readmes";
    homepage = "https://github.com/anuraghazra/github-readme-stats";
    license = lib.licenses.mit;
    mainProgram = finalAttrs.pname;
    platforms = lib.platforms.all;
  };
})
