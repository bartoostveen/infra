{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage (_finalAttrs: {
  pname = "autokuma";
  version = "0-unstable-2026-05-30";

  src = fetchFromGitHub {
    owner = "BigBoot";
    repo = "AutoKuma";
    rev = "663d259439630bd7139593313fd9a62f34200ea3";
    hash = "sha256-tPqGzzrrcLKEKsytZhO56+TznoifGTDDGFJlUaiM23A=";
  };

  cargoHash = "sha256-TG0RQ+SE/x4SKXFAzWQlu2377USyTPu5Z6oaZ9Omh9M=";

  patches = [
    ./no-doctest.patch
  ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  postInstall = ''
    mv $out/bin/crdgen $out/bin/autokuma-crdgen
  '';

  meta = {
    description = "Utility that automates the creation of Uptime Kuma monitors";
    homepage = "https://github.com/BigBoot/AutoKuma";
    mainProgram = "autokuma";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ bartoostveen ];
  };
})
