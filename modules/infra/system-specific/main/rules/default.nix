{ config, lib, ... }:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkOption
    types
    ;

  inherit (types)
    attrs
    attrsOf
    listOf
    submodule
    ;

  cfg = config.infra.monitoring;
in
{
  options.infra.monitoring = {
    groups = mkOption {
      description = "Prometheus monitoring groups";
      type = attrsOf (submodule {
        freeformType = attrs;
        options = {
          enable = mkEnableOption "this monitoring group" // {
            default = true;
          };
          rules = mkOption {
            description = "Rules within the group";
            type = attrsOf (submodule {
              freeformType = attrs;
              options.enable = mkEnableOption "this rule" // {
                default = true;
              };
            });
            default = { };
            example = { }; # TODO
          };
        };
      });
      default = { };
      example = { }; # TODO
    };
    additionalPrometheusRules = mkOption {
      description = ''
        Additional Prometheus monitoring options.

        ::: {.note}
        Use {option}`infra.monitoring.groups` instead if not importing Prometheus rules
        :::
      '';
      type = submodule {
        options = {
          groups = mkOption {
            description = "List of monitoring groups";
            type = listOf (submodule {
              freeformType = attrs;
              options = {
                enable = mkEnableOption "this monitoring group" // {
                  default = true;
                };
                rules = mkOption {
                  description = "Rules within the group";
                  type = listOf (submodule {
                    freeformType = attrs;
                    options.enable = mkEnableOption "this rule" // {
                      default = true;
                    };
                  });
                  default = [ ];
                };
              };
            });
            default = [ ];
          };
        };
        imports = [
          ./basic.nix
          ./borg.nix
          ./golang.nix
          ./loki.nix
          ./maubot.nix
          ./node.nix
          ./postgres.nix
          ./tlsa.nix
        ];
      };
    };
  };

  config.infra.monitoring = {
    groups =
      cfg.additionalPrometheusRules.groups
      |> map (group: {
        inherit (group) name;
        value =
          (removeAttrs group [
            "enable"
            "name"
          ])
          // {
            enable = mkDefault group.enable;
            rules =
              group.rules
              |> map (rule: {
                name = rule.alert;
                value =
                  (removeAttrs rule [
                    "enable"
                    "alert"
                  ])
                  // {
                    enable = mkDefault rule.enable;
                  };
              })
              |> builtins.listToAttrs;
          };
      })
      |> builtins.listToAttrs;
  };
}
