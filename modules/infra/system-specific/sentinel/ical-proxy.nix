{
  pkgs,
  inputs,
  ...
}:

let
  domain = "calendarthing.omeduostuurcentenneef.nl";
  name = "ical-proxy";
  port = 6968;
  env = {
    REDIS_ENDPOINT = "${name}-redis:6379";
    DEBUG = "1";
    PORT = toString port;
  };
  pkg = inputs.ical-proxy.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dockerImage = pkgs.dockerTools.streamLayeredImage {
    inherit name;
    tag = pkg.version;
    contents = [
      pkg
      pkgs.busybox
    ];
    config.Cmd = [ "/bin/${pkg.pname}" ];
  };
in
{
  virtualisation.oci-containers.containers = {
    ${name} = {
      image = "localhost/${name}:${pkg.version}";
      imageStream = dockerImage;
      environment = env;
      dependsOn = [ "${name}-redis" ];
      ports = [ "127.0.0.1:${toString port}:${toString port}" ];
    };
    "${name}-redis" = {
      image = "valkey/valkey:latest";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:${toString port}";
  };
}
