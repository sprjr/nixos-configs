{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.patrick.home.hyprland;

  data = import ./keybind-data.nix { inherit pkgs; };

  # Widest key string, so the plain-text sheet's keys column lines up.
  keyWidth = foldl' (a: g: foldl' (b: x: max b (stringLength x.keys)) a g.binds) 0 data.groups;
  padKey = s: s + fixedWidthString (keyWidth - stringLength s) " " "";

  # Super+N workspace / Super+Shift+N move-to-workspace for 1..0 (workspace 10).
  workspaceBinds = concatMap (n:
    let ws = if n == 0 then "10" else toString n;
    in [
      "$mainMod, ${toString n}, workspace, ${ws}"
      "$mainMod SHIFT, ${toString n}, movetoworkspace, ${ws}"
    ]) [ 1 2 3 4 5 6 7 8 9 0 ];

  hyprshort = pkgs.writeShellApplication {
    name = "hyprshort";
    text = ''
      cat <<'EOF'
      Hyprland keybindings (mainMod = SUPER)

      ${concatMapStringsSep "\n\n" (g:
        g.title + "\n" + concatMapStringsSep "\n" (b: "  ${padKey b.keys}  ${b.desc}") g.binds
      ) data.groups}
      EOF
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [ hyprshort ];

    wayland.windowManager.hyprland.settings = {
      bind = [
        "CTRL, grave, togglespecialworkspace, dropdown"

        "$mainMod, Return, exec, $terminal"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, Q, killactive,"
        "$mainMod, F, togglefloating,"
        "$mainMod, V, layoutmsg, togglesplit"
        "$mainMod, semicolon, pin,"
        "$mainMod, Escape, exec, loginctl lock-session"
        # Quit session.
        "$mainMod SHIFT, Escape, exit,"

        # Scratchpad (minimize): M to show/hide, Shift+M to send window.
        "$mainMod, M, togglespecialworkspace, magic"
        "$mainMod SHIFT, M, movetoworkspacesilent, special:magic"

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

        # Screenshots (grimblast: clipboard only).
        "$mainMod SHIFT, S, exec, grimblast copy area"
        ", Print, exec, grimblast copy screen"
      ] ++ optionals (cfg.shell == "native") [
        "$mainMod, Space, exec, fuzzel"
        "$mainMod, A, exec, control-center-toggle"
        "$mainMod, slash, exec, keybinds-toggle"
        "$mainMod, D, exec, dict-lookup --selection"
        "$mainMod SHIFT, D, exec, jp-lookup --selection"
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
