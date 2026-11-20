{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# KDE Connect phone state from D-Bus.
#   --waybar  bar button JSON (dim icon when no phone is reachable)
#   --panel   full state for the AGS phone panel (control-center/config/widget/Phone.tsx); null when no paired device
let
  cfg = config.patrick.home.hyprland;

  kdeconnectStatus = pkgs.writeShellApplication {
    name = "kdeconnect-status";
    runtimeInputs = with pkgs; [
      systemd
      jq
      coreutils
    ];
    text = ''
      mode=''${1:---waybar}
      dest=org.kde.kdeconnect
      dev_if=org.kde.kdeconnect.device

      bus() { busctl --user --auto-start=no --json=short "$@" 2>/dev/null; }

      # Property value as JSON; null when the object or plugin is missing.
      prop() {
        local v
        v=$(bus get-property "$dest" "$1" "$2" "$3" | jq -c '.data') || v=null
        printf '%s' "''${v:-null}"
      }

      # Paired device ids; $1 = only reachable.
      devices() {
        bus call "$dest" /modules/kdeconnect org.kde.kdeconnect.daemon devices bb "$1" true |
          jq -r '.data[0][]' || true
      }

      offline() {
        if [ "$mode" = "--panel" ]; then
          echo null
        else
          printf '{"text":"󰄜","tooltip":"Phone not reachable (Super B)","class":"offline"}\n'
        fi
        exit 0
      }

      id=$(devices true | head -n1)
      if [ -z "$id" ] && [ "$mode" = "--panel" ]; then
        id=$(devices false | head -n1)
      fi
      [ -n "$id" ] || offline

      dev=/modules/kdeconnect/devices/$id
      name=$(prop "$dev" "$dev_if" name)
      reachable=$(prop "$dev" "$dev_if" isReachable)
      charge=$(prop "$dev/battery" "$dev_if.battery" charge)
      charging=$(prop "$dev/battery" "$dev_if.battery" isCharging)

      if [ "$mode" != "--panel" ]; then
        jq -nc --argjson name "$name" --argjson charge "$charge" --argjson charging "$charging" '
          ($name // "Phone") as $n |
          if ($charge | type) != "number" or $charge < 0 then
            {text: "󰄜", tooltip: "\($n)\nBattery unknown (Super B)", class: "unknown"}
          else
            {
              text: "󰄜 \($charge)%",
              tooltip: "\($n)\nBattery: \($charge)%\(if $charging == true then " (charging)" else "" end)\n(Super B)",
              class: (if $charging == true then "charging"
                      elif $charge <= 15 then "critical"
                      elif $charge <= 30 then "warning"
                      else "normal" end)
            }
          end'
        exit 0
      fi

      net_type=$(prop "$dev/connectivity_report" "$dev_if.connectivity_report" cellularNetworkType)
      net_strength=$(prop "$dev/connectivity_report" "$dev_if.connectivity_report" cellularNetworkStrength)

      notifs='[]'
      ids=$(bus call "$dest" "$dev/notifications" "$dev_if.notifications" activeNotifications |
        jq -r '.data[0][]') || ids=""
      for n in $ids; do
        p=$dev/notifications/$n
        ni=$dev_if.notifications.notification
        notifs=$(jq -c --arg id "$n" \
          --argjson app "$(prop "$p" "$ni" appName)" \
          --argjson title "$(prop "$p" "$ni" title)" \
          --argjson text "$(prop "$p" "$ni" text)" \
          --argjson dismissable "$(prop "$p" "$ni" dismissable)" \
          '. + [{id: $id, app: ($app // ""), title: ($title // ""), text: ($text // ""), dismissable: ($dismissable == true)}]' \
          <<<"$notifs")
      done

      jq -nc \
        --arg id "$id" \
        --argjson name "$name" \
        --argjson reachable "$reachable" \
        --argjson charge "$charge" \
        --argjson charging "$charging" \
        --argjson netType "$net_type" \
        --argjson netStrength "$net_strength" \
        --argjson notifs "$notifs" '
        {
          id: $id,
          name: ($name // "Phone"),
          reachable: ($reachable == true),
          charge: (if ($charge | type) == "number" and $charge >= 0 then $charge else null end),
          charging: ($charging == true),
          netType: (if ($netType | type) == "string" and $netType != "Unknown" then $netType else "" end),
          netStrength: (if ($netStrength | type) == "number" and $netStrength >= 0
                        then ([$netStrength, 4] | min) else null end),
          notifs: $notifs
        }'
    '';
  };
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    home.packages = [ kdeconnectStatus ];
  };
}
