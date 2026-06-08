{ pkgs, lib, ... }:

let
  inherit (lib) concatStringsSep attrsToList;

  attrsToGlobals =
    attrs:
    attrs
    |> attrsToList
    |> map ({ name, value }: "set -g ${name} ${value}")
    |> concatStringsSep "\n";
in
{
  programs.tmux = {
    enable = true;
    mouse = true;
    clock24 = true;
    secureSocket = true;
    reverseSplit = true;
    baseIndex = 1;
    tmuxinator.enable = true;
    tmuxp.enable = true;

    extraConfig = attrsToGlobals {
      "automatic-rename" = "on";
      "allow-rename" = "on";
      "set-titles" = "on";
      "window-status-format" = "\"#I:#(basename #{pane_current_command})\"";
      "window-status-current-format" = "\"#[bold]#I:#(basename #{pane_current_command})\"";
    };

    plugins = with pkgs.tmuxPlugins; [
      cpu
      battery
      tmux-sessionx
      tmux-which-key
      {
        plugin = catppuccin;
        extraConfig = attrsToGlobals {
          "@catppuccin_flavor" = "'mocha'";
        };
      }
      {
        plugin = mkTmuxPlugin {
          pluginName = "tmux-statusline-themes";
          version = "unstable";
          src = pkgs.fetchFromGitHub {
            owner = "dmitry-kabanov";
            repo = "tmux-statusline-themes";
            rev = "5239a3b8d0de860ef573a688678c64a47d3d431f";
            hash = "sha256-A4PxrkUGZHjIt0np95848quUo42i+4CX9LwOJ5ek0/Y=";
          };
        };
        extraConfig = attrsToGlobals {
          "@tmux-statusline-theme" = "'solarized-dark'";
        };
      }
    ];
  };
}
