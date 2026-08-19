{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Galaxy Buds battery widget via BudsLink D-Bus service.
let
  cfg = config.patrick.home.hyprland;

  budslink = pkgs.writeShellApplication {
    name = "waybar-budslink";
    runtimeInputs = with pkgs; [
      glib
      jq
      coreutils
      gnused
    ];
    text = ''
      raw=$(gdbus call --session \
        --dest io.github.maniacx.BudsLink \
        --object-path /io/github/maniacx/BudsLink \
        --method io.github.maniacx.BudsLink.DeviceManager.ListDevices 2>/dev/null) || {
        printf '{"text":""}\n'
        exit 0
      }

      path=$(printf '%s' "$raw" | sed -n "s/.*'\(\/[^']*\)'.*/\1/p" | head -n1)
      if [ -z "$path" ]; then
        printf '{"text":""}\n'
        exit 0
      fi

      state_raw=$(gdbus call --session \
        --dest io.github.maniacx.BudsLink \
        --object-path "$path" \
        --method org.freedesktop.DBus.Properties.Get \
        io.github.maniacx.BudsLink.Device State 2>/dev/null) || {
        printf '{"text":""}\n'
        exit 0
      }

      json=$(printf '%s' "$state_raw" | sed "s/^(<'//;s/'>,)$//")
      if [ -z "$json" ] || ! printf '%s' "$json" | jq empty 2>/dev/null; then
        printf '{"text":""}\n'
        exit 0
      fi

      left=$(printf '%s' "$json" | jq -r '.battery1Level // empty')
      right=$(printf '%s' "$json" | jq -r '.battery2Level // empty')
      case_bat=$(printf '%s' "$json" | jq -r '.battery3Level // empty')

      if [ -z "$left" ] && [ -z "$right" ]; then
        printf '{"text":""}\n'
        exit 0
      fi

      text=""
      tooltip="Galaxy Buds"
      if [ -n "$left" ]; then
        text="L:''${left}%"
        tooltip="''${tooltip}\nLeft: ''${left}%"
      fi
      if [ -n "$right" ]; then
        [ -n "$text" ] && text="''${text} "
        text="''${text}R:''${right}%"
        tooltip="''${tooltip}\nRight: ''${right}%"
      fi
      if [ -n "$case_bat" ] && [ "$case_bat" != "0" ]; then
        tooltip="''${tooltip}\nCase: ''${case_bat}%"
      fi

      min=''${left:-100}
      [ -n "$right" ] && [ "$right" -lt "$min" ] && min=$right
      class="normal"
      [ "$min" -le 30 ] && class="warning"
      [ "$min" -le 15 ] && class="critical"

      printf '{"text":"󰥰 %s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
    '';
  };
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    home.packages = [ budslink ];
  };
}
