{ pkgs, ... }:

{
  services.phpfpm = {
    phpOptions = ''
      date.timezone = "Europe/Amsterdam"
    '';
    phpPackage = pkgs.php.buildEnv {
      extensions = ({ enabled, all }: enabled ++ (with all; [ imagick ]));
    };
  };
}
