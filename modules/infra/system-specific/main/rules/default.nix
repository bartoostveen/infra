{ lib, ... }:

# TODO: transform upon import to attribute sets to make enable options possible, make less ugly in general

let
  inherit (lib) mkOption types;
  inherit (types) submodule listOf attrs;
in
{
  options.infra.monitoring = mkOption {
    description = "Additional Prometheus monitoring options";
    type = submodule {
      options = {
        groups = mkOption {
          description = "List of monitoring groups";
          type = listOf attrs;
          default = [ ];
        };
      };

      imports = [
        ./basic.nix
        ./golang.nix
        ./loki.nix
        ./maubot.nix
        ./node.nix
        ./postgres.nix
        ./tlsa.nix
      ];
    };
  };
}
