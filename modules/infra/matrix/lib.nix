{ pkgs, ... }:

{
  mkElementCall =
    let
      inherit (pkgs) stdenv element-call;
    in
    conf:
    if (conf == { }) then
      element-call
    else
      stdenv.mkDerivation {
        pname = "${element-call.pname}-wrapped";
        inherit (element-call) version meta;

        dontUnpack = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          ln -s ${element-call}/* $out
          rm $out/config.json
          cp ${builtins.toFile "element-call-config.json" (builtins.toJSON conf)} $out/config.json
        '';
      };

  mkAutokumaMonitor = homeserver: {
    tags.matrix = {
      name = "Matrix";
      color = "#0037ff";
    };
    monitors.continuwuity = {
      type = "json-query";
      name = "Matrix federation test (${homeserver}) [federationtester.matrix.org]";
      description = "Matrix federation for ${homeserver} Managed by AutoKuma";
      url = "https://federationtester.matrix.org/api/report?server_name=${homeserver}";
      notification_name_list = [ "autokuma-matrix" ];
      tag_names = [
        {
          name = "autokuma";
          value = "Matrix";
        }
        {
          name = "matrix";
          value = homeserver;
        }
      ];
      json_path = "FederationOK";
      json_path_operator = "==";
      expected_value = "true";
      timeout = 60;
      interval = 120;
      retry_interval = 120;
    };
  };
}
