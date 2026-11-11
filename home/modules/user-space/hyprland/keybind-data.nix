{ pkgs, cfg }:

# Single source for the Hyprland binds, the hyprshort sheet and the AGS keybind panel.
# Each row carries its description plus the bind strings it documents; rows without
# bind lists are documentation only (bound elsewhere).
let
  inherit (pkgs) lib;
  inherit (lib) optional optionals concatMap filter genAttrs;

  native = cfg.shell == "native";

  # Super+N workspace / Super+Shift+N move-to-workspace for 1..0 (workspace 10).
  workspaceBinds = mods: dispatcher: map (n:
    "${mods}, ${toString n}, ${dispatcher}, ${if n == 0 then "10" else toString n}"
  ) [ 1 2 3 4 5 6 7 8 9 0 ];

  notify = {
    swaync = { toggle = "swaync-client -t -sw"; dnd = "swaync-client -d -sw"; };
    hokum = { toggle = "hokum"; dnd = "hokum dnd toggle"; };
  }.${cfg.notifications.daemon} or null;

  allGroups = [
    {
      title = "Apps & window";
      icon = "applications-system-symbolic";
      binds = [
        { keys = "Ctrl `"; desc = "dropdown terminal (toggle)"; bind = [ "CTRL, grave, togglespecialworkspace, dropdown" ]; }
      ] ++ optionals native [
        { keys = "Super Space"; desc = "app launcher (fuzzel)"; bind = [ "$mainMod, Space, exec, fuzzel" ]; }
        { keys = "Super A"; desc = "control center (toggle)"; bind = [ "$mainMod, A, exec, control-center-toggle" ]; }
        { keys = "Super /"; desc = "this cheat sheet"; bind = [ "$mainMod, slash, exec, keybinds-toggle" ]; }
        { keys = "Super I"; desc = "caffeine (idle inhibit) toggle"; bind = [ "$mainMod, I, exec, caffeine toggle" ]; }
      ] ++ [
        { keys = "Super Return"; desc = "terminal (ghostty)"; bind = [ "$mainMod, Return, exec, $terminal" ]; }
        { keys = "Super E"; desc = "file manager"; bind = [ "$mainMod, E, exec, $fileManager" ]; }
        { keys = "Super Q"; desc = "close window"; bind = [ "$mainMod, Q, killactive," ]; }
        { keys = "Super F"; desc = "toggle floating"; bind = [ "$mainMod, F, togglefloating," ]; }
        { keys = "Super V"; desc = "toggle split"; bind = [ "$mainMod, V, layoutmsg, togglesplit" ]; }
        { keys = "Super ;"; desc = "pin window (all workspaces)"; bind = [ "$mainMod, semicolon, pin," ]; }
        { keys = "Super M"; desc = "show/hide scratchpad"; bind = [ "$mainMod, M, togglespecialworkspace, magic" ]; }
        { keys = "Super Shift M"; desc = "send window to scratchpad"; bind = [ "$mainMod SHIFT, M, movetoworkspacesilent, special:magic" ]; }
        { keys = "Super Esc"; desc = "lock session"; bind = [ "$mainMod, Escape, exec, loginctl lock-session" ]; }
        { keys = "Super Shift Esc"; desc = "exit Hyprland session"; bind = [ "$mainMod SHIFT, Escape, exit," ]; }
      ];
    }
    {
      title = "Tools";
      icon = "edit-copy-symbolic";
      binds = optionals native [
        { keys = "Super C"; desc = "clipboard history (fuzzel)"; bind = [ "$mainMod, C, exec, waybar-clipboard" ]; }
        { keys = "Super P"; desc = "pick screen color"; bind = [ "$mainMod, P, exec, hyprpicker -a" ]; }
      ] ++ optionals (native && notify != null) [
        { keys = "Super N"; desc = "notification center"; bind = [ "$mainMod, N, exec, ${notify.toggle}" ]; }
        { keys = "Super Shift N"; desc = "do-not-disturb toggle"; bind = [ "$mainMod SHIFT, N, exec, ${notify.dnd}" ]; }
      ];
    }
    {
      title = "Lookup";
      icon = "accessories-dictionary-symbolic";
      binds = optionals native [
        { keys = "Super D"; desc = "English dictionary (selection or prompt)"; bind = [ "$mainMod, D, exec, dict-lookup --selection" ]; }
        { keys = "Super Shift D"; desc = "Japanese dictionary (selection or prompt)"; bind = [ "$mainMod SHIFT, D, exec, jp-lookup --selection" ]; }
      ] ++ [
        # Bound by Fcitx5 itself.
        { keys = "Ctrl Space"; desc = "toggle Japanese IME (Fcitx5)"; }
      ];
    }
    {
      title = "Window layout";
      icon = "view-fullscreen-symbolic";
      binds = [
        { keys = "Super Shift F"; desc = "fullscreen (toggle)"; bind = [ "$mainMod SHIFT, F, fullscreen," ]; }
        { keys = "Super Ctrl F"; desc = "maximize, bar stays visible"; bind = [ "$mainMod CTRL, F, fullscreen, 1" ]; }
        { keys = "Super Shift T"; desc = "pseudo-tile (dwindle)"; bind = [ "$mainMod SHIFT, T, pseudo," ]; }
        {
          keys = "Super Shift Ctrl h/j/k/l";
          desc = "swap with neighbouring window";
          bind = [
            "$mainMod SHIFT CTRL, h, swapwindow, l"
            "$mainMod SHIFT CTRL, j, swapwindow, d"
            "$mainMod SHIFT CTRL, k, swapwindow, u"
            "$mainMod SHIFT CTRL, l, swapwindow, r"
          ];
        }
        { keys = "Super Z"; desc = "swallow window (hide parent)"; bind = [ "$mainMod, Z, toggleswallow," ]; }
        { keys = "Super R"; desc = "resize mode, h/j/k/l to resize"; bind = [ "$mainMod, R, submap, resize" ]; }
        # Bound inside the resize submap (keybinds.nix).
        { keys = "Esc / Return"; desc = "leave resize mode"; }
      ];
    }
    {
      title = "Window groups";
      icon = "view-grid-symbolic";
      binds = [
        { keys = "Super G"; desc = "collapse window into a group"; bind = [ "$mainMod, G, togglegroup," ]; }
        { keys = "Super Ctrl G"; desc = "next window in group"; bind = [ "$mainMod CTRL, G, changegroupactive, f" ]; }
        { keys = "Super Shift G"; desc = "pull window out of group"; bind = [ "$mainMod SHIFT, G, moveoutofgroup," ]; }
      ];
    }
    {
      title = "Focus & monitors";
      icon = "video-display-symbolic";
      binds = [
        { keys = "Super Tab"; desc = "cycle to next window"; bind = [ "$mainMod, Tab, cyclenext," ]; }
        { keys = "Super Shift Tab"; desc = "cycle to previous window"; bind = [ "$mainMod SHIFT, Tab, cyclenext, prev" ]; }
        {
          keys = "Super Alt h/l";
          desc = "focus monitor left/right";
          bind = [ "$mainMod ALT, h, focusmonitor, l" "$mainMod ALT, l, focusmonitor, r" ];
        }
        {
          keys = "Super Alt Shift h/l";
          desc = "move window to monitor left/right";
          bind = [ "$mainMod ALT SHIFT, h, movewindow, mon:l" "$mainMod ALT SHIFT, l, movewindow, mon:r" ];
        }
      ];
    }
    {
      title = "Focus & movement";
      icon = "go-jump-symbolic";
      binds = [
        {
          keys = "Super h/j/k/l";
          desc = "focus window left/down/up/right";
          bind = [
            "$mainMod, h, movefocus, l"
            "$mainMod, j, movefocus, d"
            "$mainMod, k, movefocus, u"
            "$mainMod, l, movefocus, r"
          ];
        }
        {
          keys = "Super Shift h/j/k/l";
          desc = "move window left/down/up/right";
          bind = [
            "$mainMod SHIFT, h, movewindow, l"
            "$mainMod SHIFT, j, movewindow, d"
            "$mainMod SHIFT, k, movewindow, u"
            "$mainMod SHIFT, l, movewindow, r"
          ];
        }
      ];
    }
    {
      title = "Workspaces";
      icon = "view-app-grid-symbolic";
      binds = [
        { keys = "Super 1-0"; desc = "go to workspace 1-10"; bind = workspaceBinds "$mainMod" "workspace"; }
        { keys = "Super Shift 1-0"; desc = "move window to workspace 1-10"; bind = workspaceBinds "$mainMod SHIFT" "movetoworkspace"; }
        {
          keys = "Super Ctrl h/l";
          desc = "previous/next workspace";
          bind = [ "$mainMod CTRL, h, workspace, e-1" "$mainMod CTRL, l, workspace, e+1" ];
        }
      ];
    }
    {
      title = "Screenshots";
      icon = "camera-photo-symbolic";
      binds = [
        { keys = "Super Shift S"; desc = "area to clipboard"; bind = [ "$mainMod SHIFT, S, exec, grimblast copy area" ]; }
        { keys = "Print"; desc = "screen to clipboard"; bind = [ ", Print, exec, grimblast copy screen" ]; }
      ];
    }
    {
      title = "Mouse";
      icon = "input-mouse-symbolic";
      binds = [
        { keys = "Super LMB drag"; desc = "move window"; bindm = [ "$mainMod, mouse:272, movewindow" ]; }
        { keys = "Super RMB drag"; desc = "resize window"; bindm = [ "$mainMod, mouse:273, resizewindow" ]; }
      ];
    }
    {
      title = "Media keys";
      icon = "audio-volume-high-symbolic";
      binds = [
        {
          # Repeating, and active while locked.
          keys = "Volume / brightness";
          desc = "volume up/down, mute, brightness up/down";
          bindel = [
            ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
            ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ];
        }
        {
          # Active while locked.
          keys = "Play / Next / Prev";
          desc = "media playback (playerctl)";
          bindl = [
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPrev, exec, playerctl previous"
          ];
        }
      ];
    }
  ]
  ++ optional (native && cfg.homeAssistant.enable) {
    title = "Home Assistant";
    icon = "preferences-system-symbolic";
    binds = [
      { keys = "Super O"; desc = "office fan on for 5 minutes"; bind = [ "$mainMod, O, exec, ha-run-script script.turn_on_office_fan_for_5m" ]; }
      { keys = "Super Shift C"; desc = "camera feeds (fuzzel)"; bind = [ "$mainMod SHIFT, C, exec, ha-cameras" ]; }
    ];
  };

  groups = filter (g: g.binds != [ ]) allGroups;
  rows = concatMap (g: g.binds) groups;
in
{
  inherit groups;

  # Hyprland bind lists, gathered from every row.
  binds = genAttrs [ "bind" "bindel" "bindl" "bindm" ] (type: concatMap (r: r.${type} or [ ]) rows);

  # Panel data: keys and descriptions only.
  ts = pkgs.writeText "keybind-data.ts" ''
    export type Bind = { keys: string; desc: string }
    export type Group = { title: string; icon: string; binds: Bind[] }
    export default ${builtins.toJSON (map (g: g // {
      binds = map (r: { inherit (r) keys desc; }) g.binds;
    }) groups)} as Group[]
  '';
}
