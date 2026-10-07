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
      title = "Focus (vim)";
      icon = "zoom-in-symbolic";
      binds = [
        { keys = "Super h/j/k/l"; desc = "move focus left/down/up/right"; }
      ];
    }
    {
      title = "Move window (vim)";
      icon = "go-jump-symbolic";
      binds = [
        { keys = "Super Shift h/j/k/l"; desc = "move window left/down/up/right"; }
      ];
    }
    {
      title = "Workspaces";
      icon = "view-grid-symbolic";
      binds = [
        { keys = "Super Ctrl h/l"; desc = "previous/next workspace"; }
        { keys = "Super 1..0"; desc = "switch to workspace 1-10"; }
        { keys = "Super Shift 1..0"; desc = "move window to workspace 1-10"; }
      ];
    }
    {
      title = "Screenshots";
      icon = "camera-photo-symbolic";
      binds = [
        { keys = "Super Shift S"; desc = "region select (clipboard)"; }
        { keys = "Print"; desc = "full screen (clipboard)"; }
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
    {
      title = "Media & hardware";
      icon = "audio-volume-high-symbolic";
      binds = [
        { keys = "Fn media keys"; desc = "play/pause, next/prev (playerctl)"; }
        { keys = "Fn volume keys"; desc = "raise/lower/mute (wpctl)"; }
        { keys = "Fn brightness keys"; desc = "raise/lower (brightnessctl)"; }
      ];
    }
    {
      title = "Mouse";
      icon = "input-mouse-symbolic";
      binds = [
        { keys = "Super + left drag"; desc = "move window"; }
        { keys = "Super + right drag"; desc = "resize window"; }
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
