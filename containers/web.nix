{
  config,
  pkgs,
  inputs,
  ...
}:

let
  name = "web";
  imageName = "omeduostuurcentenneef-web";
  port = 6969;

  pkg = inputs.omeduostuurcentenneef-web.packages.${pkgs.stdenv.hostPlatform.system}.default;

  dockerImage = pkgs.dockerTools.streamLayeredImage {
    name = imageName;
    tag = pkg.version;
    contents = with pkgs; [
      pkg
      cacert
      curl
      coreutils-full
      bashInteractive
    ];
    config = {
      Cmd = [ "/bin/omeduostuurcentenneef-web" ];
      Env = [ "NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt" ];
    };
  };

  readmeStatsName = "gh-readme-stats";
  readmeStatsPkg = pkgs.local.github-readme-stats;
  readmeStatsDockerImage = pkgs.dockerTools.streamLayeredImage {
    name = readmeStatsName;
    tag = readmeStatsPkg.version;
    contents = with pkgs; [
      readmeStatsPkg
      cacert
    ];
    config = {
      Cmd = [ "/bin/github-readme-stats" ];
      Env = [ "NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt" ];
    };
  };
in
{
  virtualisation.oci-containers.containers.${name} = {
    image = "localhost/${imageName}:${pkg.version}";
    imageStream = dockerImage;
    environment = {
      PORT = toString port;
      GH_README_STATS_ENDPOINT = "http://${readmeStatsName}:9000/api?username=bartoostveen&show_icons=true&theme=gruvbox";
    };
    environmentFiles = [ config.sops.secrets.web-env.path ];
    ports = [ "127.0.0.1:${toString port}:${toString port}" ];
  };

  virtualisation.oci-containers.containers.${readmeStatsName} = {
    image = "localhost/${readmeStatsName}:${readmeStatsPkg.version}";
    imageStream = readmeStatsDockerImage;
    environmentFiles = [ config.sops.secrets.readme-stats-env.path ];
  };

  services.nginx.virtualHosts."bartoostveen.nl" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:${toString port}";
  };

  sops.secrets.web-env = {
    format = "binary";
    sopsFile = ../secrets/web.env.secret;
    restartUnits = [ "podman-${name}.service" ];
  };

  sops.secrets.readme-stats-env = {
    format = "binary";
    sopsFile = ../secrets/readme-stats.env.secret;
    restartUnits = [ "podman-${readmeStatsName}.service" ];
  };
}
