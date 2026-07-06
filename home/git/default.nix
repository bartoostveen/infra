{ pkgs, lib, ... }:

{
  imports = [ ./remotes.nix ];

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
      branch.sort = "-committerdate";
      merge.conflictStyle = "zdiff3";

      rerere.enabled = true;

      diff = {
        algorithm = "histogram";
        mnemonicPrefix = true;
      };

      push.followTags = true;
      url."forgejo@git.bartoostveen.nl:".insteadOf = "https://git.bartoostveen.nl/";
    };

    remotes = {
      "git@gitlab.utwente.nl" = {
        email = "b.oostveen@student.utwente.nl";
        name = "Oostveen, B. (Bart, Student B-TCS)";
        signingKey = "FAD453F45800E974";
      };
      "git@gitlab.snt.utwente.nl" = {
        email = "oostveen@snt.utwente.nl";
        name = "Bart Oostveen";
        signingKey = "2D4FB795E873C2C3";
      };
      "git@gitlab.ia.utwente.nl" = {
        email = "oostveenb@inter-actief.net";
        name = "Bart Oostveen";
        signingKey = "3A251B9812E9186C";
      };
    };
  };

  programs.gh = {
    enable = lib.mkDefault true;
    gitCredentialHelper.enable = true;
  };
}
