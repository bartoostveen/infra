{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  kdePackages,
  openssl,
  libpulseaudio,
  qt6,
  installShellFiles,
  copyDesktopItems,
  makeDesktopItem,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "librepods";
  version = "1.0.0-rc1";

  src = fetchFromGitHub {
    owner = "kavishdevar";
    repo = "librepods";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Q1JX83ewLgyscgcTbh6Mb21ZBCMxrOZFv1jhqNkwMUI=";
  };

  sourceRoot = "source/linux";

  nativeBuildInputs = [
    cmake
    pkg-config

    kdePackages.qtbase
    kdePackages.qtconnectivity
    kdePackages.qtdeclarative
    kdePackages.qtmultimedia
    kdePackages.qttools

    openssl
    libpulseaudio

    qt6.wrapQtAppsHook

    installShellFiles
    copyDesktopItems
  ];

  # linux/assets/me.kavishdevar.librepods.desktop
  desktopItems = [
    (makeDesktopItem {
      name = finalAttrs.pname;
      desktopName = "LibrePods";
      comment = finalAttrs.meta.description;
      icon = "librepods";
      exec = finalAttrs.meta.mainProgram;
      categories = [
        "Audio"
        "AudioVideo"
        "Utility"
        "Qt"
      ];
      terminal = false;
    })
  ];

  meta = {
    description = "AirPods liberated from Apple's ecosystem";
    homepage = "https://github.com/kavishdevar/librepods";
    changelog = "https://github.com/kavishdevar/librepods/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    mainProgram = "librepods";
    platforms = lib.platforms.all;
  };
})
