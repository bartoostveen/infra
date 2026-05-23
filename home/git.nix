{ pkgs, lib, ... }:

{
  programs.delta = {
    enable = lib.mkDefault true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = lib.mkDefault true;
    package = pkgs.gitFull;

    signing = {
      key = "5963223E57296C53";
      signByDefault = true;
    };

    settings = {
      user.email = "bart@bartoostveen.nl";
      user.name = "Bart Oostveen";

      pull.rebase = true;
      init.defaultBranch = "master";
      advice.detachedHead = false;

      core.fsmonitor = true;
      branch.sort = "-comitterdate";
      merge.conflictStyle = "zdiff3";

      rerere.enabled = true;

      diff = {
        algorithm = "histogram";
        mnemonicPrefix = true;
      };

      push.followTags = true;
    };

    includes = [
      {
        condition = "hasconfig:remote.*.url:git@gitlab.utwente.nl:*/**";
        contents.user = {
          email = "b.oostveen@student.utwente.nl";
          name = "Oostveen, B. (Bart, Student B-TCS)";
          signingKey = "FAD453F45800E974";
        };
      }
      {
        condition = "hasconfig:remote.*.url:git@gitlab.snt.utwente.nl:*/**";
        contents.user = {
          email = "oostveen@snt.utwente.nl";
          name = "Bart Oostveen";
          signingKey = "2D4FB795E873C2C3";
        };
      }
    ];
  };

  programs.gh = {
    enable = lib.mkDefault true;
    gitCredentialHelper.enable = true;
  };
}
