{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  olm,
  withGoOlm ? false,
}:

buildGoModule (finalAttrs: {
  pname = "mautrix-telegram";
  version = "0.2605.0";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "telegram";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9TCXyGvFCZAv8xIUW3oiVRv5EBdObrLuALfME/oAWBE=";
  };

  vendorHash = "sha256-xcBbBIsFXQ90WyQ8OY+CCVIiBepIlOD/o+ZjabNvM0Q=";

  ldflags = [
    "-X"
    "main.Tag=v${finalAttrs.version}"
  ];

  buildInputs = (lib.optional (!withGoOlm) olm) ++ [ stdenv.cc.cc.lib ];

  doCheck = false;
  doInstallCheck = false;

  tags = lib.optional withGoOlm "goolm";

  meta = {
    description = "A Matrix-Telegram puppeting bridge";
    homepage = "https://github.com/mautrix/telegram";
    changelog = "https://github.com/mautrix/telegram/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "mautrix-telegram";
  };
})
