{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Phone battery widget via the KDE Connect D-Bus service; empty when no device is reachable.
let
  cfg = config.patrick.home.hyprland;

  kdeconnect = pkgs.writeShellApplication {
    name = "waybar-kdeconnect";
    runtimeInputs = with pkgs; [
      glib
      coreutils
      gnused
    ];
    text = ''
      empty() {
        printf '{"text":""}\n'
        exit 0
      }

      # Read a D-Bus property and strip the gdbus "(<value>,)" wrapper and string quotes.
      prop() {
        gdbus call --session \
          --dest org.kde.kdeconnect \
          --object-path "$1" \
          --method org.freedesktop.DBus.Properties.Get "$2" "$3" 2>/dev/null |
          sed "s/^(<//;s/>,)$//;s/^'//;s/'$//"
      }

      # First reachable + paired device id.
      raw=$(gdbus call --session \
        --dest org.kde.kdeconnect \
        --object-path /modules/kdeconnect \
        --method org.kde.kdeconnect.daemon.devices true true 2>/dev/null) || empty
      id=$(printf '%s' "$raw" | sed -n "s/^(\['\([^']*\)'.*/\1/p")
      [ -n "$id" ] || empty

      dev="/modules/kdeconnect/devices/$id"
      charge=$(prop "$dev/battery" org.kde.kdeconnect.device.battery charge)
      charging=$(prop "$dev/battery" org.kde.kdeconnect.device.battery isCharging)
      name=$(prop "$dev" org.kde.kdeconnect.device name)

      case "$charge" in
        "" | -1 | *[!0-9]*) empty ;;
      esac

      class="normal"
      [ "$charge" -le 30 ] && class="warning"
      [ "$charge" -le 15 ] && class="critical"
      suffix=""
      if [ "$charging" = "true" ]; then
        class="charging"
        suffix=" (charging)"
      fi

      printf '{"text":"󰄜 %s%%","tooltip":"%s\\nBattery: %s%%%s","class":"%s"}\n' \
        "$charge" "''${name:-Phone}" "$charge" "$suffix" "$class"
    '';
  };
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    home.packages = [ kdeconnect ];
  };
}
