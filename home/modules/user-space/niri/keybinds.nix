{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.patrick.home.niri;

  # Super+N workspace / Super+Shift+N move-to-workspace for 1..0 (workspace 10).
  workspaceBinds = builtins.listToAttrs (concatMap
    (n:
      let ws = if n == 0 then 10 else n;
      in [
        {
          name = "Mod+${toString n}";
          value.action.focus-workspace = ws;
        }
        {
          name = "Mod+Shift+${toString n}";
          value.action.move-window-to-workspace = ws;
        }
      ])
    [ 1 2 3 4 5 6 7 8 9 0 ]);

  nirishort = pkgs.writeShellApplication {
    name = "nirishort";
    text = ''
      cat <<'EOF'
      Niri keybindings (Mod = Super)

      Apps & window
        Super Space            app launcher (fuzzel)
        Super Return           terminal (ghostty)
        Super E                file manager
        Super Q                close window
        Super F                toggle floating
        Super Esc              lock session
        Super Shift Esc        quit Niri session

      Column management
        Super BracketLeft      consume window into column
        Super BracketRight     expel window from column
        Super R                switch preset column width

      Focus (vim)
        Super h/l              focus column left/right
        Super j/k              focus window down/up

      Move window (vim)
        Super Shift h/l        move column left/right
        Super Shift j/k        move window down/up

      Workspaces
        Super Ctrl h/l         previous/next workspace
        Super 1..0             switch to workspace 1..10
        Super Shift 1..0       move window to workspace 1..10

      Layout
        Super C                center focused column
        Super Shift F          maximize column

      Screenshots (copied to clipboard)
        Super Shift S          region select
        Print                  full screen

      Wallpaper
        Super Shift W          rotate wallpaper now

      Media / hardware keys
        Volume, mute, brightness, and play/pause/next/prev keys are bound.

      Japanese IME
        Ctrl Space             toggle Japanese IME (Fcitx5)
      EOF
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [ nirishort ];

    programs.niri.settings.binds = {
      # Apps & window management
      "Mod+Space".action.spawn = [ "fuzzel" ];
      "Mod+Return".action.spawn = [ "ghostty" ];
      "Mod+E".action.spawn = [ "cosmic-files" ];
      "Mod+Q".action.close-window = { };
      "Mod+F".action.toggle-window-floating = { };
      "Mod+Escape".action.spawn = [ "loginctl" "lock-session" ];
      "Mod+Shift+Escape".action.quit = { };

      # Column management (niri-specific)
      "Mod+BracketLeft".action.consume-or-expel-window-left = { };
      "Mod+BracketRight".action.consume-or-expel-window-right = { };
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+C".action.center-column = { };
      "Mod+Shift+F".action.maximize-column = { };

      # Vim focus movement (column-based)
      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+J".action.focus-window-down = { };
      "Mod+K".action.focus-window-up = { };

      # Vim window/column movement
      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+L".action.move-column-right = { };
      "Mod+Shift+J".action.move-window-down = { };
      "Mod+Shift+K".action.move-window-up = { };

      # Adjacent workspace
      "Mod+Ctrl+H".action.focus-workspace-up = { };
      "Mod+Ctrl+L".action.focus-workspace-down = { };

      # Screenshots
      "Mod+Shift+S".action.screenshot = { };
      "Print".action.screenshot-screen = { };

      # Wallpaper rotation
      "Mod+Shift+W".action.spawn = [ "niri-wallpaper" ];

      # Volume / brightness (repeat + allow-when-locked)
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = [ "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "5%+" ];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
      };
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [ "brightnessctl" "set" "5%+" ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [ "brightnessctl" "set" "5%-" ];
      };

      # Media keys (allow-when-locked)
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn = [ "playerctl" "next" ];
      };
      "XF86AudioPause" = {
        allow-when-locked = true;
        action.spawn = [ "playerctl" "play-pause" ];
      };
      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn = [ "playerctl" "play-pause" ];
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn = [ "playerctl" "previous" ];
      };
    } // workspaceBinds;
  };
}
