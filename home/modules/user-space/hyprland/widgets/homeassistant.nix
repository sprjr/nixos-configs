{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Home Assistant waybar widgets, mirroring the Darwin sketchybar HA items
# (darwin/modules/sketchybar.nix). Toggles/scripts hit the HA REST API using the sops
# `ha_token` secret; state pollers emit waybar JSON with a class so CSS can recolor by state.
# Camera feeds use a fuzzel menu (waybar has no native popups). Enabled by default on every
# Hyprland host via patrick.home.hyprland.homeAssistant.enable.
let
  cfg = config.patrick.home.hyprland;
  ha = cfg.homeAssistant;
  tokenPath = config.sops.secrets."ha_token".path;

  # POST a service call: ha-call <domain>/<service> <json-body>
  ha-call = pkgs.writeShellApplication {
    name = "ha-call";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      endpoint="$1"
      body="$2"
      token=$(cat ${tokenPath})
      curl -sf -X POST \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        "${ha.url}/api/services/$endpoint" \
        -d "$body" >/dev/null || true
    '';
  };

  ha-toggle = pkgs.writeShellApplication {
    name = "ha-toggle";
    runtimeInputs = [ ha-call ];
    text = ''
      entity="$1"
      domain="''${entity%%.*}"
      ha-call "$domain/toggle" "{\"entity_id\":\"$entity\"}"
    '';
  };

  ha-run-script = pkgs.writeShellApplication {
    name = "ha-run-script";
    runtimeInputs = [ ha-call ];
    text = ''
      ha-call "script/turn_on" "{\"entity_id\":\"$1\"}"
    '';
  };

  # waybar switch state poller -> JSON {text, class} for a switch.* entity.
  mkSwitchWidget =
    name: entity: icon:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = with pkgs; [
        curl
        jq
      ];
      text = ''
        token=$(cat ${tokenPath})
        state=$(curl -sf -H "Authorization: Bearer $token" \
          "${ha.url}/api/states/${entity}" 2>/dev/null | jq -r '.state' 2>/dev/null || true)
        case "$state" in
          on)  printf '{"text":"${icon}","class":"on","tooltip":"${entity}: on"}\n' ;;
          off) printf '{"text":"${icon}","class":"off","tooltip":"${entity}: off"}\n' ;;
          *)   printf '{"text":"${icon}","class":"unavailable","tooltip":"${entity}: unavailable"}\n' ;;
        esac
      '';
    };

  waybar-ha-fan = mkSwitchWidget "waybar-ha-fan" "switch.s40lite_0_2" "󰈐";
  waybar-ha-lamp = mkSwitchWidget "waybar-ha-lamp" "switch.s40lite_0" "󰌵";

  # Motion sensor: active / "Nm ago" with recency class.
  waybar-ha-motion = pkgs.writeShellApplication {
    name = "waybar-ha-motion";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = ''
      entity="binary_sensor.lumi_lumi_motion_ac02_occupancy"
      token=$(cat ${tokenPath})
      resp=$(curl -sf -H "Authorization: Bearer $token" "${ha.url}/api/states/$entity" || true)
      if [ -z "$resp" ]; then
        printf '{"text":"","class":"unavailable","tooltip":"motion: unavailable"}\n'
        exit 0
      fi
      state=$(printf '%s' "$resp" | jq -r '.state')
      changed=$(printf '%s' "$resp" | jq -r '.last_changed')
      if [ "$state" = "on" ]; then
        printf '{"text":" active","class":"active","tooltip":"motion active"}\n'
      elif [ "$state" = "unavailable" ]; then
        printf '{"text":"","class":"unavailable","tooltip":"motion: unavailable"}\n'
      else
        secs=$(( $(date +%s) - $(date -d "$changed" +%s) ))
        if [ "$secs" -lt 60 ]; then label="''${secs}s ago"; cls="recent"
        elif [ "$secs" -lt 3600 ]; then label="$(( secs / 60 ))m ago"; cls="idle"
        else label="$(( secs / 3600 ))h ago"; cls="stale"
        fi
        printf '{"text":" %s","class":"%s","tooltip":"last motion %s"}\n' "$label" "$cls" "$label"
      fi
    '';
  };

  # Camera feeds via a fuzzel menu (opens the HA proxy stream in the default browser).
  ha-cameras = pkgs.writeShellApplication {
    name = "ha-cameras";
    runtimeInputs = with pkgs; [
      fuzzel
      xdg-utils
    ];
    text = ''
      choice=$(printf 'Camera 1 (4.6)\nCamera 2 (4.7)\n' | fuzzel --dmenu --prompt "Camera: " || true)
      case "$choice" in
        "Camera 1 (4.6)") xdg-open "${ha.url}/api/camera_proxy_stream/camera.192_168_4_6" ;;
        "Camera 2 (4.7)") xdg-open "${ha.url}/api/camera_proxy_stream/camera.192_168_4_7" ;;
      esac
    '';
  };
in
{
  config = mkIf (cfg.enable && ha.enable) {
    sops.secrets."ha_token" = { };

    home.packages = [
      ha-call
      ha-toggle
      ha-run-script
      waybar-ha-fan
      waybar-ha-lamp
      waybar-ha-motion
      ha-cameras
    ];
  };
}
