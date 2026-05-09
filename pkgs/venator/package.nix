{
  lib,
  buildGoModule,
  fetchFromGitea,
  go,
  mdbook,
  versionCheckHook,
  withDocs ? true,
}:

buildGoModule (finalAttrs: {
  pname = "venator";
  version = "0.2605.09";
  __structuredAttrs = true;

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "timedout";
    repo = "venator";
    rev = "dcf06e86c5224b25b045573f054ba9d2d4bbb92e";
    hash = "sha256-2CLrzk9Z6i1wa3nkMF6jVq24GRggzQTfo42NmrskpgE=";
    fetchSubmodules = true; # because Codeberg or smth
  };

  vendorHash = "sha256-vnZbYMXEbwrHDz5OI4UDAyAZC3xE0zrWljvgBki8d8M=";

  preBuild = lib.optionalString withDocs ''
    if [ -d vendor ]; then
      go generate -tags "$VENATOR_BUILD_TAGS" ./internal/embedded_docs/
    fi
  '';

  nativeBuildInputs = lib.optional withDocs mdbook ++ [
    versionCheckHook
  ];

  tags = lib.optional withDocs "docs";

  env = {
    VENATOR_BUILD_TAGS = lib.concatStringsSep "," finalAttrs.tags;
    GOEXPERIMENT = "jsonv2";
  };

  ldflags = [
    "-s"
    "-w"
    "-X"
    "codeberg.org/timedout/venator/version.LatestTag=${finalAttrs.version}"
    "-X"
    "codeberg.org/timedout/venator/version.CurrentTag=${finalAttrs.version}"
    "-X"
    "codeberg.org/timedout/venator/version.CommitHash=${finalAttrs.src.rev}"
    "-X"
    "codeberg.org/timedout/venator/version.Dirty=false"
    "-X"
    "codeberg.org/timedout/venator/version.BuildDate=\"1970.01.01T00.00.00Z\""
    "-X"
    "codeberg.org/timedout/venator/version.GoVersion=${go.version}"
    "-X"
    "codeberg.org/timedout/venator/version.OSArch=${finalAttrs.goModules.GOARCH}"
  ];

  meta = {
    description = "Matrix Venator - versatile capital Matrix homeserver written from scratch in mautrix-go";
    homepage = "https://codeberg.org/timedout/venator";
    license = lib.licenses.mpl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "venatorctl";
  };
})
