{ pkgs, ... }:

{
  services.phpfpm = {
    phpOptions = ''
      date.timezone = "Europe/Amsterdam"
    '';
    phpPackage = pkgs.php85.buildEnv {
      extensions = { enabled, all }: enabled ++ (with all; [ imagick ]);
    };
  };
}
