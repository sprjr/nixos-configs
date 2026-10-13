{ pkgs }:

# Single source for the hyprshort sheet and the AGS keybind panel.
let
  groups = [
    {
      title = "Apps & window";
      icon = "applications-system-symbolic";
      binds = [
        { keys = "Ctrl `"; desc = "dropdown terminal (toggle)"; }
        { keys = "Super Space"; desc = "app launcher (fuzzel)"; }
        { keys = "Super A"; desc = "control center (toggle)"; }
        { keys = "Super /"; desc = "this cheat sheet"; }
        { keys = "Super Return"; desc = "terminal (ghostty)"; }
        { keys = "Super E"; desc = "file manager"; }
        { keys = "Super Q"; desc = "close window"; }
        { keys = "Super F"; desc = "toggle floating"; }
        { keys = "Super V"; desc = "toggle split"; }
        { keys = "Super ;"; desc = "pin window (all workspaces)"; }
        { keys = "Super M"; desc = "show/hide scratchpad"; }
        { keys = "Super Shift M"; desc = "send window to scratchpad"; }
        { keys = "Super Esc"; desc = "lock session"; }
        { keys = "Super Shift Esc"; desc = "exit Hyprland session"; }
      ];
    }
    {
      title = "Lookup";
      icon = "accessories-dictionary-symbolic";
      binds = [
        { keys = "Super D"; desc = "English dictionary (selection or prompt)"; }
        { keys = "Super Shift D"; desc = "Japanese dictionary (selection or prompt)"; }
        { keys = "Ctrl Space"; desc = "toggle Japanese IME (Fcitx5)"; }
      ];
    }
  ];
in
{
  inherit groups;

  ts = pkgs.writeText "keybind-data.ts" ''
    export type Bind = { keys: string; desc: string }
    export type Group = { title: string; icon: string; binds: Bind[] }
    export default ${builtins.toJSON groups} as Group[]
  '';
}
