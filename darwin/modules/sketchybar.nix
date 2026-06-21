{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.patrick.darwin.sketchybar;
  space-sh = pkgs.writeShellScriptBin "space.sh" ''
    if [ "$SELECTED" = "true" ]
    then
      sketchybar -m --set $NAME background.color=0xff81a1c1
    else
      sketchybar -m --set $NAME background.color=0xff57627A
    fi
  '';
  window-title-sh = pkgs.writeShellScriptBin "window_title.sh" ''
    WINDOW_TITLE=$(${pkgs.yabai}/bin/yabai -m query --windows --window | ${pkgs.jq}/bin/jq -r '.app')
    if [[ $WINDOW_TITLE != "" ]]; then
      sketchybar -m --set title label="$WINDOW_TITLE"
    else
      sketchybar -m --set title label=None
    fi
  '';
  date-time-sh = pkgs.writeShellScriptBin "date-time.sh" ''
    sketchybar -m --set $NAME label="$(date '+%a %d %b %H:%M')"
  '';
  top-mem-sh = pkgs.writeShellScriptBin "top-mem.sh" ''
    TOPPROC=$(ps axo "%cpu,ucomm" | sort -nr | tail +1 | head -n1 | awk '{printf "%.0f%% %s\n", $1, $2}' | sed -e 's/com.apple.//g')
    TOPMEM=$(ps axo "rss" | sort -nr | tail +1 | head -n1 | awk '{printf "%.0fMB %s\n", $1 / 1024, $2}' | sed -e 's/com.apple.//g')
    MEM=$(echo $TOPMEM | sed -nr 's/([^MB]+).*/\1/p')
    sketchybar -m --set $NAME label="$TOPMEM"
  '';
  cpu-sh = pkgs.writeShellScriptBin "cpu.sh" ''
    CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
    CPU_INFO=$(ps -eo pcpu,user)
    CPU_SYS=$(echo "$CPU_INFO" | grep -v $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
    CPU_USER=$(echo "$CPU_INFO" | grep $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
    sketchybar -m --set  cpu_percent label=$(echo "$CPU_SYS $CPU_USER" | awk '{printf "%.0f\n", ($1 + $2)*100}')%
  '';
  caffeine-sh = pkgs.writeShellScriptBin "caffeine.sh" ''
    if pgrep -q 'caffeinate'
    then
      sketchybar --set $NAME icon="󰅶"
    else
      sketchybar --set $NAME icon="󰛊"
    fi
  '';
  caffeine-click-sh = pkgs.writeShellScriptBin "caffeine-click.sh" ''
    if pgrep -q 'caffeinate'
    then
      killall caffeinate
      sketchybar --set $NAME icon="󰛊"
    else
      caffeinate -d & disown
      sketchybar --set $NAME icon="󰅶"
    fi
  '';
  battery-sh = pkgs.writeShellScriptBin "battery.sh" ''
    if pmset -g ac | grep -q 'Family Code = 0x0000' # No battery (i.e. Mac Mini, Mac Pro, etc.)
    then
      sketchybar \
        --set $NAME \
          icon.color="0xFFFFFFFF" \
          icon="󰚥" \
          label="AC"
    else
      data=$(pmset -g batt)
      battery_percent=$(echo $data | grep -Eo "\d+%" | cut -d% -f1)
      charging=$(echo $data | grep 'AC Power')

      case "$battery_percent" in
        100)    icon="󰁹" color=0xFFFFFFFF ;;
        9[0-9]) icon="󰂂" color=0xFFFFFFFF ;;
        8[0-9]) icon="󰂁" color=0xFFFFFFFF ;;
        7[0-9]) icon="󰂀" color=0xFFFFFFFF ;;
        6[0-9]) icon="󰁿" color=0xFFFFFFFF ;;
        5[0-9]) icon="󰁾" color=0xFFFFFFFF ;;
        4[0-9]) icon="󰁽" color=0xFFFFFFFF ;;
        3[0-9]) icon="󰁼" color=0xFFFFFFFF ;;
        2[0-9]) icon="󰁻" color=0xFFFFFFFF ;;
        1[0-9]) icon="󰁺" color=0xFFFFFFFF ;;
        *)      icon="󰂃" color=0xFFFFFFFF ;;
      esac

      # if is charging
      if ! [ -z "$charging" ]; then
        icon="$icon 󰚥"
      fi

      sketchybar \
        --set $NAME \
          icon.color="$color" \
          icon="$icon" \
          label="$battery_percent%"
    fi
  '';
  top-proc-sh = pkgs.writeShellScriptBin "top-proc.sh" ''
    TOPPROC=$(ps axo "%cpu,ucomm" | sort -nr | tail +1 | head -n1 | awk '{printf "%.0f%% %s\n", $1, $2}' | sed -e 's/com.apple.//g')
    CPUP=$(echo $TOPPROC | sed -nr 's/([^\%]+).*/\1/p')
    if [ $CPUP -gt 75 ]; then
      sketchybar -m --set $NAME label="$TOPPROC"
    else
      sketchybar -m --set $NAME label=""
    fi
  '';
  spotify-indicator-sh = pkgs.writeShellScriptBin "spotify-indicator.sh" ''
    RUNNING="$(osascript -e 'if application "Spotify" is running then return 0')"
    if [ $RUNNING != 0 ]
    then
      RUNNING=1
    fi
    PLAYING=1
    TRACK=""
    ALBUM=""
    ARTIST=""
    if [[ $RUNNING -eq 0 ]]
    then
      [[ "$(osascript -e 'if application "Spotify" is running then tell application "Spotify" to get player state')" == "playing" ]] && PLAYING=0
      TRACK="$(osascript -e 'tell application "Spotify" to get name of current track')"
      ARTIST="$(osascript -e 'tell application "Spotify" to get artist of current track')"
      ALBUM="$(osascript -e 'tell application "Spotify" to get album of current track')"
    fi
    if [[ -n "$TRACK" ]]
    then
      sketchybar -m --set "$NAME" drawing=on
      [[ "$PLAYING" -eq 0 ]] && ICON=""
      [[ "$PLAYING" -eq 1 ]] && ICON=""
      if [ "$ARTIST" == "" ]
      then
        sketchybar -m --set "$NAME" label="''${ICON} ''${TRACK} - ''${ALBUM}"
      else
        sketchybar -m --set "$NAME" label="''${ICON} ''${TRACK} - ''${ARTIST}"
      fi
    else
      sketchybar -m --set "$NAME" label="" drawing=off
    fi
  '';
  # HA: poll switch.s40lite_0_2 (box fan) state, update icon color
  ha-fan-state-sh = pkgs.writeShellScriptBin "ha-fan-state.sh" ''
    TOKEN=$(cat /run/secrets/ha_token)
    STATE=$(curl -sf -H "Authorization: Bearer $TOKEN" \
      http://shikisha:8123/api/states/switch.s40lite_0_2 | ${pkgs.jq}/bin/jq -r '.state')
    if [ "$STATE" = "on" ]; then
      sketchybar --set "$NAME" icon.color=0xff81a1c1
    else
      sketchybar --set "$NAME" icon.color=0xffeceff4
    fi
  '';
  # HA: toggle switch.s40lite_0_2 (box fan) and immediately reflect new state
  ha-fan-click-sh = pkgs.writeShellScriptBin "ha-fan-click.sh" ''
    TOKEN=$(cat /run/secrets/ha_token)
    curl -sf -X POST \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      http://shikisha:8123/api/services/switch/toggle \
      -d '{"entity_id":"switch.s40lite_0_2"}' > /dev/null
    sleep 0.3
    STATE=$(curl -sf -H "Authorization: Bearer $TOKEN" \
      http://shikisha:8123/api/states/switch.s40lite_0_2 | ${pkgs.jq}/bin/jq -r '.state')
    if [ "$STATE" = "on" ]; then
      sketchybar --set ha_fan icon.color=0xff81a1c1
    else
      sketchybar --set ha_fan icon.color=0xffeceff4
    fi
  '';
  # HA: poll switch.s40lite_0 (floor lamp) state, update icon color
  ha-lamp-state-sh = pkgs.writeShellScriptBin "ha-lamp-state.sh" ''
    TOKEN=$(cat /run/secrets/ha_token)
    STATE=$(curl -sf -H "Authorization: Bearer $TOKEN" \
      http://shikisha:8123/api/states/switch.s40lite_0 | ${pkgs.jq}/bin/jq -r '.state')
    if [ "$STATE" = "on" ]; then
      sketchybar --set "$NAME" icon.color=0xff81a1c1
    else
      sketchybar --set "$NAME" icon.color=0xffeceff4
    fi
  '';
  # HA: toggle switch.s40lite_0 (floor lamp) and immediately reflect new state
  ha-lamp-click-sh = pkgs.writeShellScriptBin "ha-lamp-click.sh" ''
    TOKEN=$(cat /run/secrets/ha_token)
    curl -sf -X POST \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      http://shikisha:8123/api/services/switch/toggle \
      -d '{"entity_id":"switch.s40lite_0"}' > /dev/null
    sleep 0.3
    STATE=$(curl -sf -H "Authorization: Bearer $TOKEN" \
      http://shikisha:8123/api/states/switch.s40lite_0 | ${pkgs.jq}/bin/jq -r '.state')
    if [ "$STATE" = "on" ]; then
      sketchybar --set ha_lamp icon.color=0xff81a1c1
    else
      sketchybar --set ha_lamp icon.color=0xffeceff4
    fi
  '';
  # HA: poll binary_sensor.lumi_lumi_motion_ac02_occupancy and display state + recency
  ha-motion-state-sh = pkgs.writeShellScriptBin "ha-motion-state.sh" ''
    TOKEN=$(cat /run/secrets/ha_token)
    RESPONSE=$(curl -sf -H "Authorization: Bearer $TOKEN" \
      http://shikisha:8123/api/states/binary_sensor.lumi_lumi_motion_ac02_occupancy)
    if [ -z "$RESPONSE" ]; then exit 0; fi

    STATE=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.state')
    LAST_CHANGED=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.last_changed')

    if [ "$STATE" = "on" ]; then
      sketchybar --set "$NAME" icon.color=0xff81a1c1 label="active"
    elif [ "$STATE" = "unavailable" ]; then
      sketchybar --set "$NAME" icon.color=0xff57627A label=""
    else
      RESULT=$(python3 -c "
from datetime import datetime, timezone
delta = datetime.now(timezone.utc) - datetime.fromisoformat('$LAST_CHANGED')
secs = int(delta.total_seconds())
label = (str(secs) + 's ago') if secs < 60 else ((str(secs // 60) + 'm ago') if secs < 3600 else (str(secs // 3600) + 'h ago'))
color = '0xff81a1c1' if secs < 300 else ('0xffeceff4' if secs < 3600 else '0xff57627A')
print(label)
print(color)
")
      ELAPSED=$(echo "$RESULT" | head -1)
      COLOR=$(echo "$RESULT" | tail -1)
      sketchybar --set "$NAME" icon.color=$COLOR label="$ELAPSED"
    fi
  '';
  # HA: trigger script.turn_on_office_fan_for_5m
  ha-office-fan-5m-sh = pkgs.writeShellScriptBin "ha-office-fan-5m.sh" ''
    TOKEN=$(cat /run/secrets/ha_token)
    curl -sf -X POST \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      http://shikisha:8123/api/services/script/turn_on \
      -d '{"entity_id":"script.turn_on_office_fan_for_5m"}' > /dev/null
  '';
  # Timer: countdown loop that updates the timer bar item label each second
  timer-countdown-sh = pkgs.writeShellScriptBin "timer-countdown.sh" ''
    DURATION=$1
    END=$(($(date +%s) + DURATION))
    PIDFILE=/tmp/sketchybar-timer.pid
    echo $$ > "$PIDFILE"
    while [ "$(date +%s)" -lt "$END" ]; do
      REMAINING=$((END - $(date +%s)))
      MINS=$((REMAINING / 60))
      SECS=$((REMAINING % 60))
      sketchybar --set timer label="$(printf '%02d:%02d' $MINS $SECS)"
      sleep 1
    done
    rm -f "$PIDFILE"
    sketchybar --set timer label="done" icon.color=0xff81a1c1
    afplay /System/Library/Sounds/Glass.aiff
    osascript -e 'display notification "Timer complete!" with title "Timer" sound name "Glass"'
    sleep 3
    sketchybar --set timer label="" icon.color=0xffeceff4
  '';
  # Timer: kill any running countdown, then start a new one in background
  timer-start-sh = pkgs.writeShellScriptBin "timer-start.sh" ''
    DURATION=$1
    PIDFILE=/tmp/sketchybar-timer.pid
    if [ -f "$PIDFILE" ]; then
      kill "$(cat $PIDFILE)" 2>/dev/null || true
      rm -f "$PIDFILE"
    fi
    sketchybar --set timer popup.drawing=off
    ${timer-countdown-sh}/bin/timer-countdown.sh "$DURATION" &
    disown
  '';
in {

  options = {
    patrick.darwin.sketchybar.enable = mkOption {
      default = false;
      description = ''
        Enable heywoodlh nord-themed sketchybar.
      '';
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."ha_token" = {
      owner = "patrick";
      mode = "0400";
    };
    system.defaults.NSGlobalDomain._HIHideMenuBar = true; # Disable menu bar
    homebrew = {
      casks = [
        "font-jetbrains-mono-nerd-font"
      ];
    };
    services.sketchybar = {
      enable = true;
      extraPackages = with pkgs; [
        jetbrains-mono
      ];
      config = ''
        ############## BAR ##############
          sketchybar -m --bar \
            height=32 \
            position=top \
            padding_left=5 \
            padding_right=5 \
            color=0xff2e3440 \
            shadow=off \
            sticky=on \
            topmost=off

        ############## GLOBAL DEFAULTS ##############
          sketchybar -m --default \
            updates=when_shown \
            drawing=on \
            cache_scripts=on \
            icon.font="JetBrainsMono Nerd Font Mono:Bold:18.0" \
            icon.color=0xffffffff \
            label.font="JetBrainsMono Nerd Font Mono:Bold:12.0" \
            label.color=0xffeceff4 \
            label.highlight_color=0xff8CABC8

        ############## SPACE DEFAULTS ##############
          sketchybar -m --default \
            label.padding_left=3 \
            label.padding_right=2 \
            icon.padding_left=4 \
            label.padding_right=4

        ############## PRIMARY DISPLAY SPACES ##############
          # APPLE ICON
          sketchybar -m --add item apple left \
            --set apple icon=$'\xef\x85\xb9' \
            --set apple icon.font="JetBrainsMono Nerd Font Mono:Regular:20.0" \
            --set apple label.padding_right=0 \

          # SPACE 1: CODE ICON (launches Ghostty terminal, active on space 1)
          sketchybar -m --add space code left \
            --set code icon=$'\xef\x84\xa1' \
            --set code associated_space=1 \
            --set code icon.padding_left=5 \
            --set code icon.padding_right=5 \
            --set code label.padding_right=0 \
            --set code label.padding_left=0 \
            --set code label.color=0xffeceff4 \
            --set code background.color=0xff57627A  \
            --set code background.height=21 \
            --set code background.padding_left=7 \
            --set code click_script="$HOME/.nix-profile/bin/ghostty" \

          # SPACE 2: WEB ICON (disabled)
          # sketchybar -m --add space web left \
          #   --set web icon= \
          #   --set web icon.highlight_color=0xff8CABC8 \
          #   --set web associated_space=1 \
          #   --set web icon.padding_left=5 \
          #   --set web icon.padding_right=5 \
          #   --set web label.padding_right=0 \
          #   --set web label.padding_left=0 \
          #   --set web label.color=0xffeceff4 \
          #   --set web background.color=0xff57627A  \
          #   --set web background.height=21 \
          #   --set web background.padding_left=12 \
          #   --set web click_script="open -a Firefox.app" \

          # SPACE 3: MUSIC ICON (opens Spotify in browser)
          sketchybar -m --add space music left \
            --set music icon=$'\xef\x80\x81' \
            --set music icon.highlight_color=0xff8CABC8 \
            --set music associated_display=1 \
            --set music associated_space=5 \
            --set music icon.padding_left=5 \
            --set music icon.padding_right=5 \
            --set music label.padding_right=0 \
            --set music label.padding_left=0 \
            --set music label.color=0xffeceff4 \
            --set music background.color=0xff57627A  \
            --set music background.height=21 \
            --set music background.padding_left=7 \
            --set music click_script="open -a Firefox.app 'https://spotify.com'" \

          # SPOTIFY STATUS / CURRENT TRACK
          sketchybar -m --add event spotify_change "com.spotify.client.PlaybackStateChanged" \
            --add item spotify_indicator left \
            --set spotify_indicator background.color=0xff57627A  \
            --set spotify_indicator background.height=21 \
            --set spotify_indicator background.padding_left=7 \
            --set spotify_indicator script="${spotify-indicator-sh}/bin/spotify-indicator.sh" \
            --set spotify_indicator click_script="osascript -e 'tell application \"Spotify\" to pause'" \
            --subscribe spotify_indicator spotify_change \

        ############## HOME AUTOMATION & UTILITIES ##############
          # BOX FAN TOGGLE (switch.s40lite_0_2)
          # Icon brightens (nord blue) when on, dims when off; polls HA every 30s
          sketchybar -m --add item ha_fan left \
            --set ha_fan icon=󰈐 \
            --set ha_fan icon.color=0xffeceff4 \
            --set ha_fan icon.padding_left=5 \
            --set ha_fan icon.padding_right=5 \
            --set ha_fan label.padding_right=0 \
            --set ha_fan label.padding_left=0 \
            --set ha_fan background.color=0xff57627A \
            --set ha_fan background.height=21 \
            --set ha_fan background.padding_left=7 \
            --set ha_fan update_freq=30 \
            --set ha_fan script="${ha-fan-state-sh}/bin/ha-fan-state.sh" \
            --set ha_fan click_script="${ha-fan-click-sh}/bin/ha-fan-click.sh" \

          # FLOOR LAMP TOGGLE (switch.s40lite_0)
          sketchybar -m --add item ha_lamp left \
            --set ha_lamp icon=󰌵 \
            --set ha_lamp icon.color=0xffeceff4 \
            --set ha_lamp icon.padding_left=5 \
            --set ha_lamp icon.padding_right=5 \
            --set ha_lamp label.padding_right=0 \
            --set ha_lamp label.padding_left=0 \
            --set ha_lamp background.color=0xff57627A \
            --set ha_lamp background.height=21 \
            --set ha_lamp background.padding_left=7 \
            --set ha_lamp update_freq=30 \
            --set ha_lamp script="${ha-lamp-state-sh}/bin/ha-lamp-state.sh" \
            --set ha_lamp click_script="${ha-lamp-click-sh}/bin/ha-lamp-click.sh" \

          # OFFICE FAN 5M (script.turn_on_office_fan_for_5m)
          sketchybar -m --add item ha_script left \
            --set ha_script icon=󰐊 \
            --set ha_script icon.padding_left=5 \
            --set ha_script icon.padding_right=5 \
            --set ha_script label.padding_right=0 \
            --set ha_script label.padding_left=0 \
            --set ha_script background.color=0xff57627A \
            --set ha_script background.height=21 \
            --set ha_script background.padding_left=7 \
            --set ha_script click_script="${ha-office-fan-5m-sh}/bin/ha-office-fan-5m.sh" \

          # MOTION SENSOR (binary_sensor.lumi_lumi_motion_ac02_occupancy)
          # Icon: bright = active or recent (<5m), white = 5-60m ago, dim = >1h ago
          sketchybar -m --add item ha_motion left \
            --set ha_motion icon=$'\xef\x80\x87' \
            --set ha_motion icon.color=0xff57627A \
            --set ha_motion icon.padding_left=5 \
            --set ha_motion icon.padding_right=5 \
            --set ha_motion label.padding_right=5 \
            --set ha_motion label.padding_left=3 \
            --set ha_motion background.color=0xff57627A \
            --set ha_motion background.height=21 \
            --set ha_motion background.padding_left=7 \
            --set ha_motion update_freq=30 \
            --set ha_motion script="${ha-motion-state-sh}/bin/ha-motion-state.sh" \

          # CAMERA FEEDS (popup — requires Firefox session logged into HA)
          sketchybar -m --add item ha_cameras left \
            --set ha_cameras icon=󰄀 \
            --set ha_cameras icon.padding_left=5 \
            --set ha_cameras icon.padding_right=5 \
            --set ha_cameras label.padding_right=0 \
            --set ha_cameras label.padding_left=0 \
            --set ha_cameras background.color=0xff57627A \
            --set ha_cameras background.height=21 \
            --set ha_cameras background.padding_left=7 \
            --set ha_cameras popup.background.color=0xff2e3440 \
            --set ha_cameras popup.background.border_width=2 \
            --set ha_cameras popup.background.border_color=0xff57627A \
            --set ha_cameras click_script="sketchybar --set ha_cameras popup.drawing=toggle" \

          sketchybar -m --add item ha_cameras.cam1 popup.ha_cameras \
            --set ha_cameras.cam1 icon=󰄀 \
            --set ha_cameras.cam1 label="Camera 1 (4.6)" \
            --set ha_cameras.cam1 icon.padding_left=8 \
            --set ha_cameras.cam1 icon.padding_right=5 \
            --set ha_cameras.cam1 label.padding_right=10 \
            --set ha_cameras.cam1 click_script="open -a Firefox.app 'http://shikisha:8123/api/camera_proxy_stream/camera.192_168_4_6'; sketchybar --set ha_cameras popup.drawing=off" \

          sketchybar -m --add item ha_cameras.cam2 popup.ha_cameras \
            --set ha_cameras.cam2 icon=󰄀 \
            --set ha_cameras.cam2 label="Camera 2 (4.7)" \
            --set ha_cameras.cam2 icon.padding_left=8 \
            --set ha_cameras.cam2 icon.padding_right=5 \
            --set ha_cameras.cam2 label.padding_right=10 \
            --set ha_cameras.cam2 click_script="open -a Firefox.app 'http://shikisha:8123/api/camera_proxy_stream/camera.192_168_4_7'; sketchybar --set ha_cameras popup.drawing=off" \

          # TIMER (popup with preset durations; label shows live countdown when active)
          sketchybar -m --add item timer left \
            --set timer icon=󱎫 \
            --set timer label="" \
            --set timer icon.padding_left=5 \
            --set timer icon.padding_right=5 \
            --set timer label.padding_right=5 \
            --set timer label.padding_left=3 \
            --set timer background.color=0xff57627A \
            --set timer background.height=21 \
            --set timer background.padding_left=7 \
            --set timer popup.background.color=0xff2e3440 \
            --set timer popup.background.border_width=2 \
            --set timer popup.background.border_color=0xff57627A \
            --set timer click_script="sketchybar --set timer popup.drawing=toggle" \

          sketchybar -m --add item timer.2m popup.timer \
            --set timer.2m icon=󱎫 \
            --set timer.2m label="2 min" \
            --set timer.2m icon.padding_left=8 \
            --set timer.2m icon.padding_right=5 \
            --set timer.2m label.padding_right=10 \
            --set timer.2m click_script="${timer-start-sh}/bin/timer-start.sh 120" \

          sketchybar -m --add item timer.5m popup.timer \
            --set timer.5m icon=󱎫 \
            --set timer.5m label="5 min" \
            --set timer.5m icon.padding_left=8 \
            --set timer.5m icon.padding_right=5 \
            --set timer.5m label.padding_right=10 \
            --set timer.5m click_script="${timer-start-sh}/bin/timer-start.sh 300" \

          sketchybar -m --add item timer.15m popup.timer \
            --set timer.15m icon=󱎫 \
            --set timer.15m label="15 min" \
            --set timer.15m icon.padding_left=8 \
            --set timer.15m icon.padding_right=5 \
            --set timer.15m label.padding_right=10 \
            --set timer.15m click_script="${timer-start-sh}/bin/timer-start.sh 900" \

          sketchybar -m --add item timer.25m popup.timer \
            --set timer.25m icon=󱎫 \
            --set timer.25m label="25 min" \
            --set timer.25m icon.padding_left=8 \
            --set timer.25m icon.padding_right=5 \
            --set timer.25m label.padding_right=10 \
            --set timer.25m click_script="${timer-start-sh}/bin/timer-start.sh 1500" \

          sketchybar -m --add item timer.60m popup.timer \
            --set timer.60m icon=󱎫 \
            --set timer.60m label="60 min" \
            --set timer.60m icon.padding_left=8 \
            --set timer.60m icon.padding_right=5 \
            --set timer.60m label.padding_right=10 \
            --set timer.60m click_script="${timer-start-sh}/bin/timer-start.sh 3600" \

          # STEAM LAUNCHER
          sketchybar -m --add item steam left \
            --set steam icon=󰓓 \
            --set steam icon.padding_left=5 \
            --set steam icon.padding_right=5 \
            --set steam label.padding_right=0 \
            --set steam label.padding_left=0 \
            --set steam background.color=0xff57627A \
            --set steam background.height=21 \
            --set steam background.padding_left=7 \
            --set steam click_script="open -a Steam.app" \

        ############## ITEM DEFAULTS ###############
          sketchybar -m --default \
            label.padding_left=2 \
            icon.padding_right=2 \
            icon.padding_left=6 \
            label.padding_right=6

        ############## RIGHT ITEMS ##############
          # DATE TIME
          sketchybar -m --add item date_time right \
            --set date_time icon= \
            --set date_time icon.padding_left=8 \
            --set date_time icon.padding_right=0 \
            --set date_time label.padding_right=9 \
            --set date_time label.padding_left=6 \
            --set date_time label.color=0xffeceff4 \
            --set date_time update_freq=20 \
            --set date_time background.color=0xff57627A \
            --set date_time background.height=21 \
            --set date_time background.padding_right=12 \
            --set date_time script="${date-time-sh}/bin/date-time.sh" \

          # Battery STATUS
          sketchybar -m --add item battery right \
            --set battery icon.font="JetBrainsMono Nerd Font Mono:Bold:10.0" \
            --set battery icon.padding_left=8 \
            --set battery icon.padding_right=8 \
            --set battery label.padding_right=8 \
            --set battery label.padding_left=0 \
            --set battery label.color=0xffffffff \
            --set battery background.color=0xff57627A  \
            --set battery background.height=21 \
            --set battery background.padding_right=7 \
            --set battery update_freq=10 \
            --set battery script="${battery-sh}/bin/battery.sh" \

          # RAM USAGE
          sketchybar -m --add item topmem right \
            --set topmem icon= \
            --set topmem icon.padding_left=8 \
            --set topmem icon.padding_right=0 \
            --set topmem label.padding_right=8 \
            --set topmem label.padding_left=6 \
            --set topmem label.color=0xffeceff4 \
            --set topmem background.color=0xff57627A  \
            --set topmem background.height=21 \
            --set topmem background.padding_right=7 \
            --set topmem update_freq=2 \
            --set topmem script="${top-mem-sh}/bin/top-mem.sh" \

          # CPU USAGE
          sketchybar -m --add item cpu_percent right \
            --set cpu_percent icon= \
            --set cpu_percent icon.padding_left=8 \
            --set cpu_percent icon.padding_right=0 \
            --set cpu_percent label.padding_right=8 \
            --set cpu_percent label.padding_left=6 \
            --set cpu_percent label.color=0xffeceff4 \
            --set cpu_percent background.color=0xff57627A  \
            --set cpu_percent background.height=21 \
            --set cpu_percent background.padding_right=7 \
            --set cpu_percent update_freq=2 \
            --set cpu_percent script="${cpu-sh}/bin/cpu.sh" \

          # CAFFEINE
          sketchybar -m --add item caffeine right \
            --set caffeine icon.padding_left=8 \
            --set caffeine icon.padding_right=0 \
            --set caffeine label.padding_right=0 \
            --set caffeine label.padding_left=6 \
            --set caffeine label.color=0xffeceff4 \
            --set caffeine background.color=0xff57627A  \
            --set caffeine background.height=21 \
            --set caffeine background.padding_right=7 \
            --set caffeine script="${caffeine-sh}/bin/caffeine.sh" \
            --set caffeine click_script="${caffeine-click-sh}/bin/caffeine-click.sh" \

          # TOP PROCESS
          sketchybar -m --add item topproc right \
            --set topproc drawing=on \
            --set topproc label.padding_right=10 \
            --set topproc update_freq=15 \
            --set topproc script="${top-proc-sh}/bin/topproc.sh"

        ###################### CENTER ITEMS ###################


        ############## FINALIZING THE SETUP ##############
        sketchybar -m --update

        echo "sketchybar configuration loaded.."
      '';
    };
  };
}
