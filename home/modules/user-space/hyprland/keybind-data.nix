{ pkgs, ha ? true }:

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
      title = "Tools";
      icon = "edit-copy-symbolic";
      binds = [
        { keys = "Super C"; desc = "clipboard history (fuzzel)"; }
        { keys = "Super P"; desc = "pick screen color"; }
        { keys = "Super N"; desc = "notification center"; }
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
      title = "Window layout";
      icon = "view-fullscreen-symbolic";
      binds = [
        { keys = "Super Shift F"; desc = "fullscreen (toggle)"; }
        { keys = "Super Ctrl F"; desc = "maximize, bar stays visible"; }
        { keys = "Super Shift T"; desc = "pseudo-tile (dwindle)"; }
        { keys = "Super Shift Ctrl h/j/k/l"; desc = "swap with neighbouring window"; }
        { keys = "Super Z"; desc = "swallow window (hide parent)"; }
        { keys = "Super R"; desc = "resize mode, h/j/k/l to resize"; }
        { keys = "Esc / Return"; desc = "leave resize mode"; }
      ];
    }
    {
      title = "Window groups";
      icon = "view-grid-symbolic";
      binds = [
        { keys = "Super G"; desc = "collapse window into a group"; }
        { keys = "Super Ctrl G"; desc = "next window in group"; }
        { keys = "Super Shift G"; desc = "pull window out of group"; }
      ];
    }
    {
      title = "Focus & monitors";
      icon = "video-display-symbolic";
      binds = [
        { keys = "Super Tab"; desc = "cycle to next window"; }
        { keys = "Super Shift Tab"; desc = "cycle to previous window"; }
        { keys = "Super Alt h/l"; desc = "focus monitor left/right"; }
        { keys = "Super Alt Shift h/l"; desc = "move window to monitor left/right"; }
      ];
    }
  ]
  ++ pkgs.lib.optional ha {
    title = "Home Assistant";
    icon = "preferences-system-symbolic";
    binds = [
      { keys = "Super O"; desc = "office fan on for 5 minutes"; }
      { keys = "Super Shift C"; desc = "camera feeds (fuzzel)"; }
    ];
  };
in
{
  inherit groups;

  ts = pkgs.writeText "keybind-data.ts" ''
    export type Bind = { keys: string; desc: string }
    export type Group = { title: string; icon: string; binds: Bind[] }
    export default ${builtins.toJSON groups} as Group[]
  '';
}
