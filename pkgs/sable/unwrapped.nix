{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  pnpmConfigHook,
  nodejs_24,
}:

let
  pnpm = pnpm_10;
  nodejs = nodejs_24;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "sable";
  version = "1.18.1";

  src = fetchFromGitHub {
    owner = "SableClient";
    repo = "Sable";
    tag = "v${finalAttrs.version}";
    hash = "sha256-puZPqdBsbCDF/t2C6Emx/LF+zfc2zLfEncQ6UZGNL30=";
  };

  patches = [
    ./0001-warming-up.patch
  ];

  nativeBuildInputs = [
    pnpm
    pnpmConfigHook
    nodejs
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-cIdtzUAh1lSLUo0RZQun7bDM3xJ3peN6K7FcIWfTpRw=";
  };

  buildPhase = ''
    runHook preBuild

    pnpm build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -r dist $out

    runHook postInstall
  '';

  meta = {
    description = "An almost stable Matrix client";
    homepage = "https://github.com/SableClient/Sable";
    changelog = "https://github.com/SableClient/Sable/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    mainProgram = "sable";
    platforms = lib.platforms.all;
  };
})
