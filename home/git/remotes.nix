{ config, lib, ... }:

let
  inherit (lib) mkOption types mapAttrsToList;
  inherit (types) attrsOf attrs;

  cfg = config.programs.git.remotes;
in
{
  options.programs.git.remotes = mkOption {
    description = "Git remote-specific user config";
    type = attrsOf attrs;
    default = { };
    example = { }; # TODO
  };
  config.programs.git.includes = mapAttrsToList (remote: c: {
    condition = "hasconfig:remote.*.url:${remote}:*/**";
    contents.user = c;
  }) cfg;
}
