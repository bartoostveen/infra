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
  version = "0.2605.13";
  __structuredAttrs = true;

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "timedout";
    repo = "venator";
    rev = "1203bc7e6d333f5dee7cecf8e6cf5824a7e26a39";
    hash = "sha256-wcKzQBshWBIEPo1MydfYs4pjEN298G1a9JSus/bd17Y=";
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
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "venatorctl";
  };
})
