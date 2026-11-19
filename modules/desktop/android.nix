{ pkgs, ... }:

let
  android = pkgs.androidenv.composeAndroidPackages {
    includeNDK = true;
    buildToolsVersions = [
      "36.0.0"
      "35.0.0"
    ];
    platformVersions = [ "37.2" ];
    includeSystemImages = true;
    systemImageTypes = [
      "google_apis_playstore"
      "google_apis_playstore_ps16k"
    ];
    includeEmulator = true;
    includeSources = true;
  };
in
{
  environment.systemPackages = [
    (pkgs.androidStudioPackages.canary.withSdk android.androidsdk)
    pkgs.android-tools
    android.androidsdk
  ];
}
