{ pkgs, ... }:

let
  android = pkgs.androidenv.composeAndroidPackages {
    includeNDK = true;
    buildToolsVersions = [
      "36.0.0"
      "35.0.0"
    ];
    platformVersions = [ "37" ];
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    includeEmulator = true;
    includeSources = true;
  };
in
{
  environment.systemPackages = with pkgs; [
    (android-studio.withSdk android.androidsdk)
    android.androidsdk
    android-tools
  ];
}
