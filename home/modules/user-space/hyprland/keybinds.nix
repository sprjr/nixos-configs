{ config, pkgs, lib, ... }:

with lib;

# Vim-style navigation with COSMIC feature parity. Binds attach to the shared
# wayland.windowManager.hyprland.settings from default.nix.
let
  cfg = config.patrick.home.hyprland;

  # Super+N workspace / Super+Shift+N move-to-workspace for 1..0 (workspace 10).
  workspaceBinds = concatMap (n:
    let ws = if n == 0 then "10" else toString n;
    in [
      "$mainMod, ${toString n}, workspace, ${ws}"
      "$mainMod SHIFT, ${toString n}, movetoworkspace, ${ws}"
    ]) [ 1 2 3 4 5 6 7 8 9 0 ];

  # `hyprshort` — printed cheatsheet of the binds defined below. Static text: keep it in sync
  # with the `bind`/`bindm` lists in this file when binds change.
  hyprshort = pkgs.writeShellApplication {
    name = "hyprshort";
    text = ''
      cat <<'EOF'
      Hyprland keybindings (mainMod = SUPER)

      Apps & window
        Super Space            app launcher (fuzzel)
        Super Return           terminal (ghostty)
        Super E                file manager
        Super Q                close window
        Super F                toggle floating
        Super V                toggle split
        Super ;                pin window (all workspaces)
        Super L                lock session
        Super Shift Esc        exit Hyprland session

      Scratchpad (minimize)
        Super M                show/hide scratchpad
        Super Shift M          send window to scratchpad

      Focus (vim)
        Super h/j/k/l          move focus left/down/up/right

      Move window (vim)
        Super Shift h/j/k/l    move window left/down/up/right

      Workspaces
        Super Ctrl h/l         previous/next workspace
        Super 1..0             switch to workspace 1..10
        Super Shift 1..0       move window to workspace 1..10

      Screenshots (copied to clipboard)
        Super Shift S          region select
        Print                  full screen

      Wallpaper
        Super Shift W          rotate wallpaper now

      Mouse
        Super + left drag      move window
        Super + right drag     resize window

      Media / hardware keys
        Volume, mute, brightness, and play/pause/next/prev keys are bound.
      EOF
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [ hyprshort ];

    wayland.windowManager.hyprland.settings = {
      bind = [
        "$mainMod, Space, exec, fuzzel"
        "$mainMod, Return, exec, $terminal"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, Q, killactive,"
        "$mainMod, F, togglefloating,"
        "$mainMod, V, layoutmsg, togglesplit"
        "$mainMod, semicolon, pin,"
        "$mainMod, L, exec, loginctl lock-session"
        # Quit the Hyprland session back to the greeter (moved off Super+Shift+M).
        "$mainMod SHIFT, Escape, exit,"

        # Scratchpad — Hyprland's stand-in for minimize. Super+M shows/hides the special
        # "magic" workspace; Super+Shift+M sends the focused window there (minimize). To restore
        # one, show the scratchpad, focus the window, then Super+Shift+<n> to move it to a normal
        # workspace.
        "$mainMod, M, togglespecialworkspace, magic"
        "$mainMod SHIFT, M, movetoworkspacesilent, special:magic"

        # Immediate wallpaper rotation (auto-rotates every 30m via systemd timer).
        "$mainMod SHIFT, W, exec, hypr-wallpaper"

        # Vim focus movement.
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, d"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, r"

        # Vim window movement.
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, j, movewindow, d"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, l, movewindow, r"

        # Adjacent workspace.
        "$mainMod CTRL, h, workspace, e-1"
        "$mainMod CTRL, l, workspace, e+1"

        # Screenshots (grim + slurp).
        "$mainMod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
        ", Print, exec, grim - | wl-copy"
      ] ++ workspaceBinds;

      # Repeating + lock-screen-active volume/brightness keys.
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      # Media keys, active while locked.
      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      # Mouse drag move/resize.
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
