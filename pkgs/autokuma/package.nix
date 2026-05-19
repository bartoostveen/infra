{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage (_finalAttrs: {
  pname = "autokuma";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "bartoostveen";
    repo = "AutoKuma";
    rev = "7d616e1b4a47059610f25c10cff3fb4e3b5d3110";
    hash = "sha256-eMyG4LXyhdzXy4tvlnxfVukB7CdQrSHRyMjTuVlqyVE=";
  };

  cargoHash = "sha256-+pMxHwFjX00O81EwQtGzh0M6YktP1wXNavhGoFUfjno=";

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
