{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_24,
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

  patches = [
    # as specified in https://github.com/anuraghazra/github-readme-stats?tab=readme-ov-file#on-other-platforms
    # ./0001-fix-express-dependency.patch
  ];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out/
    makeWrapper ${lib.getExe nodejs_24} $out/bin/${finalAttrs.pname} --append-flag "$out/express.js"
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
