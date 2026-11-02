{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Home Assistant waybar widgets (mirrors darwin/modules/sketchybar.nix).
let
  cfg = config.patrick.home.niri;
  ha = cfg.homeAssistant;
  tokenPath = config.sops.secrets."ha_token".path;

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
in
{
  config = mkIf (cfg.enable && ha.enable) {
    sops.secrets."ha_token" = { };

    home.packages = [
      ha-call
      ha-toggle
      waybar-ha-fan
      waybar-ha-lamp
    ];
  };
}
