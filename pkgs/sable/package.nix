{
  callPackage,
  stdenv,
  sable ? callPackage ./unwrapped.nix { },
  conf ? { },
}:

if (conf == { }) then
  sable
else
  stdenv.mkDerivation {
    pname = "${sable.pname}-wrapped";
    inherit (sable) version meta;

    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      ln -s ${sable}/* $out
      rm $out/config.json
      cp ${builtins.toFile "sable-config.json" (builtins.toJSON conf)} $out/config.json
    '';
  }
