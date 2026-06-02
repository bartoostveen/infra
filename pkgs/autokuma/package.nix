{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage (_finalAttrs: {
  pname = "autokuma";
  version = "0-unstable-2026-06-03";

  src = fetchFromGitHub {
    owner = "BigBoot";
    repo = "AutoKuma";
    rev = "3379fbaeb27d66a5b8d977e66765d8b4eca94bef";
    hash = "sha256-blt2G/3yf+rBqH39buUaeIL0JDbc2SGwMsJgLtyqz9M=";
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
