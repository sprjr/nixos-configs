{ pkgs, cfg }:

# Single source for the Hyprland binds, the hyprshort sheet and the AGS keybind panel
# (passed to programs.agsPanels.keybinds in default.nix).
# Each row carries its description plus the binds it documents; rows without bind
# lists are documentation only (bound elsewhere).
let
  inherit (pkgs) lib;
  inherit (lib) optional optionals concatMap filter;
  inherit (lib.generators) toLua mkLuaInline;

  native = cfg.shell == "native";

  # Lua bind spec: key combo, dispatcher expression, optional bind options.
  k = keys: dsp: { inherit keys dsp; };
  ko = keys: dsp: opts: { inherit keys dsp opts; };

  exec = cmd: "hl.dsp.exec_cmd(${toLua { } cmd})";
  dir = d: "{ direction = ${toLua { } d} }";

  # Super+N workspace / Super+Shift+N move-to-workspace for 1..0 (workspace 10).
  workspaceBinds = mods: mkDsp: map (n:
    k "${mods} + ${toString n}" (mkDsp (if n == 0 then 10 else n))
  ) [ 1 2 3 4 5 6 7 8 9 0 ];

  notify = {
    swaync = { toggle = "swaync-client -t -sw"; dnd = "swaync-client -d -sw"; };
    hokum = { toggle = "hokum"; dnd = "hokum dnd toggle"; };
  }.${cfg.notifications.daemon} or null;

  repeatLocked = { repeating = true; locked = true; };
  locked = { locked = true; };

  allGroups = [
    {
      title = "Apps & window";
      icon = "applications-system-symbolic";
      binds = [
        { keys = "Ctrl `"; desc = "dropdown terminal (toggle)"; bind = [ (k "CTRL + grave" ''hl.dsp.workspace.toggle_special("dropdown")'') ]; }
      ] ++ optionals native [
        { keys = "Super Space"; desc = "app launcher (fuzzel)"; bind = [ (k "SUPER + Space" (exec "fuzzel")) ]; }
        { keys = "Super A"; desc = "control center (toggle)"; bind = [ (k "SUPER + A" (exec "control-center-toggle")) ]; }
        { keys = "Super /"; desc = "this cheat sheet"; bind = [ (k "SUPER + slash" (exec "keybinds-toggle")) ]; }
        { keys = "Super B"; desc = "phone panel (KDE Connect)"; bind = [ (k "SUPER + B" (exec "phone-panel-toggle")) ]; }
        { keys = "Super I"; desc = "caffeine (idle inhibit) toggle"; bind = [ (k "SUPER + I" (exec "caffeine toggle")) ]; }
      ] ++ [
        { keys = "Super Return"; desc = "terminal (ghostty)"; bind = [ (k "SUPER + Return" (exec "ghostty")) ]; }
        { keys = "Super E"; desc = "file manager"; bind = [ (k "SUPER + E" (exec "cosmic-files")) ]; }
        { keys = "Super Q"; desc = "close window"; bind = [ (k "SUPER + Q" "hl.dsp.window.close()") ]; }
        { keys = "Super F"; desc = "toggle floating"; bind = [ (k "SUPER + F" ''hl.dsp.window.float({ action = "toggle" })'') ]; }
        { keys = "Super V"; desc = "toggle split"; bind = [ (k "SUPER + V" ''hl.dsp.layout("togglesplit")'') ]; }
        { keys = "Super ;"; desc = "pin window (all workspaces)"; bind = [ (k "SUPER + semicolon" "hl.dsp.window.pin()") ]; }
        { keys = "Super M"; desc = "show/hide scratchpad"; bind = [ (k "SUPER + M" ''hl.dsp.workspace.toggle_special("magic")'') ]; }
        { keys = "Super Shift M"; desc = "send window to scratchpad"; bind = [ (k "SUPER + SHIFT + M" ''hl.dsp.window.move({ workspace = "special:magic", follow = false })'') ]; }
        { keys = "Super Esc"; desc = "lock session"; bind = [ (k "SUPER + Escape" (exec "loginctl lock-session")) ]; }
        { keys = "Super Shift Esc"; desc = "exit Hyprland session"; bind = [ (k "SUPER + SHIFT + Escape" "hl.dsp.exit()") ]; }
      ];
    }
    {
      title = "Tools";
      icon = "edit-copy-symbolic";
      binds = optionals native [
        { keys = "Super C"; desc = "clipboard history (fuzzel)"; bind = [ (k "SUPER + C" (exec "waybar-clipboard")) ]; }
        { keys = "Super P"; desc = "pick screen color"; bind = [ (k "SUPER + P" (exec "hyprpicker -a")) ]; }
        { keys = "Super T"; desc = "start countdown timer (fuzzel)"; bind = [ (k "SUPER + T" (exec "timer-start")) ]; }
      ] ++ optionals (native && notify != null) [
        { keys = "Super N"; desc = "notification center"; bind = [ (k "SUPER + N" (exec notify.toggle)) ]; }
        { keys = "Super Shift N"; desc = "do-not-disturb toggle"; bind = [ (k "SUPER + SHIFT + N" (exec notify.dnd)) ]; }
      ];
    }
    {
      title = "Lookup";
      icon = "accessories-dictionary-symbolic";
      binds = optionals native [
        { keys = "Super D"; desc = "English dictionary (selection or prompt)"; bind = [ (k "SUPER + D" (exec "ghostty --class=kotoba -e kotoba en --selection")) ]; }
        { keys = "Super Shift D"; desc = "Japanese dictionary (selection or prompt)"; bind = [ (k "SUPER + SHIFT + D" (exec "ghostty --class=kotoba -e kotoba jp --selection")) ]; }
      ] ++ [
        # Bound by Fcitx5 itself.
        { keys = "Ctrl Space"; desc = "toggle Japanese IME (Fcitx5)"; }
      ];
    }
    {
      title = "Window layout";
      icon = "view-fullscreen-symbolic";
      binds = [
        { keys = "Super Shift F"; desc = "fullscreen (toggle)"; bind = [ (k "SUPER + SHIFT + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'') ]; }
        { keys = "Super Ctrl F"; desc = "maximize, bar stays visible"; bind = [ (k "SUPER + CTRL + F" ''hl.dsp.window.fullscreen({ mode = "maximized" })'') ]; }
        { keys = "Super Shift T"; desc = "pseudo-tile (dwindle)"; bind = [ (k "SUPER + SHIFT + T" "hl.dsp.window.pseudo()") ]; }
        {
          keys = "Super Shift Ctrl h/j/k/l";
          desc = "swap with neighbouring window";
          bind = [
            (k "SUPER + SHIFT + CTRL + h" "hl.dsp.window.swap(${dir "left"})")
            (k "SUPER + SHIFT + CTRL + j" "hl.dsp.window.swap(${dir "down"})")
            (k "SUPER + SHIFT + CTRL + k" "hl.dsp.window.swap(${dir "up"})")
            (k "SUPER + SHIFT + CTRL + l" "hl.dsp.window.swap(${dir "right"})")
          ];
        }
        { keys = "Super Z"; desc = "swallow window (hide parent)"; bind = [ (k "SUPER + Z" "hl.dsp.window.toggle_swallow()") ]; }
        { keys = "Super R"; desc = "resize mode, h/j/k/l to resize"; bind = [ (k "SUPER + R" ''hl.dsp.submap("resize")'') ]; }
        # Bound inside the resize submap (keybinds.nix).
        { keys = "Esc / Return"; desc = "leave resize mode"; }
      ];
    }
    {
      title = "Window groups";
      icon = "view-grid-symbolic";
      binds = [
        { keys = "Super G"; desc = "collapse window into a group"; bind = [ (k "SUPER + G" "hl.dsp.group.toggle()") ]; }
        { keys = "Super Ctrl G"; desc = "next window in group"; bind = [ (k "SUPER + CTRL + G" "hl.dsp.group.next()") ]; }
        { keys = "Super Shift G"; desc = "pull window out of group"; bind = [ (k "SUPER + SHIFT + G" "hl.dsp.window.move({ out_of_group = true })") ]; }
      ];
    }
    {
      title = "Focus & monitors";
      icon = "video-display-symbolic";
      binds = [
        { keys = "Super Tab"; desc = "cycle to next window"; bind = [ (k "SUPER + Tab" "hl.dsp.window.cycle_next()") ]; }
        { keys = "Super Shift Tab"; desc = "cycle to previous window"; bind = [ (k "SUPER + SHIFT + Tab" "hl.dsp.window.cycle_next({ next = false })") ]; }
        {
          keys = "Super Alt h/l";
          desc = "focus monitor left/right";
          bind = [
            (k "SUPER + ALT + h" ''hl.dsp.focus({ monitor = "l" })'')
            (k "SUPER + ALT + l" ''hl.dsp.focus({ monitor = "r" })'')
          ];
        }
        {
          keys = "Super Alt Shift h/l";
          desc = "move window to monitor left/right";
          bind = [
            (k "SUPER + ALT + SHIFT + h" ''hl.dsp.window.move({ monitor = "l", follow = true })'')
            (k "SUPER + ALT + SHIFT + l" ''hl.dsp.window.move({ monitor = "r", follow = true })'')
          ];
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
            (k "SUPER + h" "hl.dsp.focus(${dir "left"})")
            (k "SUPER + j" "hl.dsp.focus(${dir "down"})")
            (k "SUPER + k" "hl.dsp.focus(${dir "up"})")
            (k "SUPER + l" "hl.dsp.focus(${dir "right"})")
          ];
        }
        {
          keys = "Super Shift h/j/k/l";
          desc = "move window left/down/up/right";
          bind = [
            (k "SUPER + SHIFT + h" "hl.dsp.window.move(${dir "left"})")
            (k "SUPER + SHIFT + j" "hl.dsp.window.move(${dir "down"})")
            (k "SUPER + SHIFT + k" "hl.dsp.window.move(${dir "up"})")
            (k "SUPER + SHIFT + l" "hl.dsp.window.move(${dir "right"})")
          ];
        }
      ];
    }
    {
      title = "Workspaces";
      icon = "view-app-grid-symbolic";
      binds = [
        { keys = "Super 1-0"; desc = "go to workspace 1-10"; bind = workspaceBinds "SUPER" (n: "hl.dsp.focus({ workspace = ${toString n} })"); }
        { keys = "Super Shift 1-0"; desc = "move window to workspace 1-10"; bind = workspaceBinds "SUPER + SHIFT" (n: "hl.dsp.window.move({ workspace = ${toString n}, follow = true })"); }
        {
          keys = "Super Ctrl h/l";
          desc = "previous/next workspace";
          bind = [
            (k "SUPER + CTRL + h" ''hl.dsp.focus({ workspace = "e-1" })'')
            (k "SUPER + CTRL + l" ''hl.dsp.focus({ workspace = "e+1" })'')
          ];
        }
      ];
    }
    {
      title = "Screenshots";
      icon = "camera-photo-symbolic";
      binds = [
        { keys = "Super Shift S"; desc = "area to clipboard"; bind = [ (k "SUPER + SHIFT + S" (exec "grimblast copy area")) ]; }
        { keys = "Print"; desc = "screen to clipboard"; bind = [ (k "Print" (exec "grimblast copy screen")) ]; }
      ];
    }
    {
      title = "Mouse";
      icon = "input-mouse-symbolic";
      binds = [
        { keys = "Super LMB drag"; desc = "move window"; bind = [ (ko "SUPER + mouse:272" "hl.dsp.window.drag()" { mouse = true; }) ]; }
        { keys = "Super RMB drag"; desc = "resize window"; bind = [ (ko "SUPER + mouse:273" "hl.dsp.window.resize()" { mouse = true; }) ]; }
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
          bind = [
            (ko "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+") repeatLocked)
            (ko "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") repeatLocked)
            (ko "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") repeatLocked)
            (ko "XF86MonBrightnessUp" (exec "brightnessctl set 5%+") repeatLocked)
            (ko "XF86MonBrightnessDown" (exec "brightnessctl set 5%-") repeatLocked)
          ];
        }
        {
          # Active while locked.
          keys = "Play / Next / Prev";
          desc = "media playback (playerctl)";
          bind = [
            (ko "XF86AudioNext" (exec "playerctl next") locked)
            (ko "XF86AudioPause" (exec "playerctl play-pause") locked)
            (ko "XF86AudioPlay" (exec "playerctl play-pause") locked)
            (ko "XF86AudioPrev" (exec "playerctl previous") locked)
          ];
        }
      ];
    }
  ]
  ++ optional (native && cfg.homeAssistant.enable) {
    title = "Home Assistant";
    icon = "preferences-system-symbolic";
    binds = [
      { keys = "Super O"; desc = "office fan on for 5 minutes"; bind = [ (k "SUPER + O" (exec "ha-run-script script.turn_on_office_fan_for_5m")) ]; }
      { keys = "Super Shift C"; desc = "camera feeds (fuzzel)"; bind = [ (k "SUPER + SHIFT + C" (exec "ha-cameras")) ]; }
    ];
  };

  groups = filter (g: g.binds != [ ]) allGroups;
  rows = concatMap (g: g.binds) groups;
in
{
  inherit groups;

  # Renders a bind spec as home-manager Lua `hl.bind(...)` arguments.
  toBind = b: { _args = [ b.keys (mkLuaInline b.dsp) ] ++ optional (b ? opts) b.opts; };

  # Bind specs gathered from every row.
  binds = concatMap (r: r.bind or [ ]) rows;
}
