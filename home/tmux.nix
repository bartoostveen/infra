{ pkgs, lib, ... }:

let
  inherit (lib) concatStringsSep attrsToList;

  attrsToGlobals =
    attrs:
    (
      attrs
      |> attrsToList
      |> map ({ name, value }: "set -g ${name} ${value}")
      |> concatStringsSep "\n"
    )
    + "\n";
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

    extraConfig =
      (attrsToGlobals {
        "automatic-rename" = "on";
        "allow-rename" = "on";
        "set-titles" = "on";
        "window-status-format" = "\"#I:#(basename #{pane_current_command})\"";
        "window-status-current-format" = "\"#[bold]#I:#(basename #{pane_current_command})\"";
      })
      + ''
        bind S run-shell "tmux setw synchronize-panes && tmux display 'Synchronize panes toggled'"
      '';

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
        plugin = pkgs.local.tmux-statusline-themes;
        extraConfig = attrsToGlobals {
          "@tmux-statusline-theme" = "'solarized-dark'";
        };
      }
    ];
  };
}
