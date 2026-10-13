{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Caffeine: logind idle inhibitor shared by the bar icon and Super I.
let
  cfg = config.patrick.home.hyprland;

  caffeine = pkgs.writeShellApplication {
    name = "caffeine";
    runtimeInputs = with pkgs; [
      coreutils
      libnotify
      procps
      systemd
    ];
    text = ''
      rt="''${XDG_RUNTIME_DIR:-/tmp}"
      pidf="$rt/caffeine.pid"

      active() {
        [ -s "$pidf" ] || return 1
        kill -0 "$(cat "$pidf")" 2>/dev/null
      }

      refresh_bar() {
        pkill -SIGRTMIN+8 -x waybar 2>/dev/null || true
      }

      notify() {
        notify-send -a caffeine "Caffeine" "$1" || true
      }

      start() {
        if active; then return 0; fi
        rm -f "$pidf"
        set -m
        systemd-inhibit --what=idle --mode=block --who=caffeine --why="Caffeine mode (Super I)" sleep infinity >/dev/null 2>&1 &
        echo $! > "$pidf"
        set +m
        refresh_bar
      }

      stop() {
        local pid=""
        if [ -s "$pidf" ]; then pid="$(cat "$pidf")"; fi
        if [ -n "$pid" ]; then
          kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
        fi
        rm -f "$pidf"
        refresh_bar
      }

      case "''${1:-status}" in
        on) start ;;
        off) stop ;;
        toggle)
          if active; then
            stop
            notify "Idle inhibit off"
          else
            start
            notify "Idle inhibit on"
          fi
          ;;
        status)
          if active; then
            printf '{"text":"󰅶","alt":"on","class":"activated"}\n'
          else
            rm -f "$pidf"
            printf '{"text":"󰾪","alt":"off","class":"deactivated"}\n'
          fi
          ;;
        *)
          printf 'usage: caffeine [status|on|off|toggle]\n' >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    home.packages = [ caffeine ];
  };
}
