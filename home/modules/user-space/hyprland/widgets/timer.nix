{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Countdown timer waybar widget mirroring the Darwin sketchybar timer: a fuzzel menu picks a
# preset duration, a detached countdown writes the remaining time to a runtime state file, and
# the waybar module renders it live. Completion fires a desktop notification.
let
  cfg = config.patrick.home.hyprland;

  timer-countdown = pkgs.writeShellApplication {
    name = "timer-countdown";
    runtimeInputs = with pkgs; [
      coreutils
      libnotify
      pulseaudio
    ];
    text = ''
      secs="$1"
      rt="''${XDG_RUNTIME_DIR:-/tmp}"
      state="$rt/waybar-timer"
      pidf="$rt/waybar-timer.pid"
      echo $$ > "$pidf"
      end=$(( $(date +%s) + secs ))
      while [ "$(date +%s)" -lt "$end" ]; do
        rem=$(( end - $(date +%s) ))
        printf '%02d:%02d' $(( rem / 60 )) $(( rem % 60 )) > "$state"
        sleep 1
      done
      printf 'done' > "$state"
      notify-send "Timer" "Timer complete" || true
      # Audible chime on expiry (played twice so it's noticeable).
      paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga || true
      paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga || true
      sleep 3
      : > "$state"
      rm -f "$pidf"
    '';
  };

  timer-start = pkgs.writeShellApplication {
    name = "timer-start";
    runtimeInputs = with pkgs; [
      fuzzel
      util-linux
      coreutils
      timer-countdown
    ];
    text = ''
      rt="''${XDG_RUNTIME_DIR:-/tmp}"
      state="$rt/waybar-timer"
      pidf="$rt/waybar-timer.pid"
      choice=$(printf '2 min\n5 min\n15 min\n25 min\n60 min\nStop\n' \
        | fuzzel --dmenu --prompt "Timer: " || true)
      if [ -f "$pidf" ]; then
        kill "$(cat "$pidf")" 2>/dev/null || true
        rm -f "$pidf"
      fi
      case "$choice" in
        "2 min")  secs=120 ;;
        "5 min")  secs=300 ;;
        "15 min") secs=900 ;;
        "25 min") secs=1500 ;;
        "60 min") secs=3600 ;;
        "Stop")   : > "$state"; exit 0 ;;
        *)        exit 0 ;;
      esac
      setsid -f timer-countdown "$secs"
    '';
  };

  waybar-timer = pkgs.writeShellApplication {
    name = "waybar-timer";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/tmp}/waybar-timer"
      if [ -s "$state" ]; then
        printf '{"text":"󱎫 %s","class":"running","tooltip":"timer"}\n' "$(cat "$state")"
      else
        printf '{"text":"󱎫","class":"idle","tooltip":"timer"}\n'
      fi
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [
      timer-countdown
      timer-start
      waybar-timer
    ];
  };
}
