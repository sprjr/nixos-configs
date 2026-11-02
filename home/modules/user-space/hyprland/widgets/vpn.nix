{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# VPN status waybar widget: tailscale (tailscale0) and netbird (netbird0, see
# nixos/modules/network/netbird-client.nix). A VPN counts as up when its interface
# holds an IPv4 address; no daemon socket access needed.
let
  cfg = config.patrick.home.hyprland;

  waybar-vpn = pkgs.writeShellApplication {
    name = "waybar-vpn";
    runtimeInputs = with pkgs; [
      iproute2
      jq
    ];
    text = ''
      ip4() {
        ip -4 -j addr show dev "$1" 2>/dev/null | jq -r '.[0].addr_info[0].local // empty' || true
      }

      ts=$(ip4 tailscale0)
      nb=$(ip4 netbird0)

      labels=""
      [ -n "$ts" ] && labels="$labels TS"
      [ -n "$nb" ] && labels="$labels NB"

      if [ -n "$labels" ]; then
        class="active"
      else
        class="off"
      fi

      jq -nc \
        --arg text "󰖂$labels" \
        --arg class "$class" \
        --arg tooltip "Tailscale: ''${ts:-down}"$'\n'"NetBird: ''${nb:-down}" \
        '{text: $text, class: $class, tooltip: $tooltip}'
    '';
  };
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    home.packages = [ waybar-vpn ];
  };
}
