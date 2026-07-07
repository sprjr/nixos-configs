{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# waybar public/private IP modules. Exposed on PATH as `waybar-public-ip` and
# `waybar-private-ip`, referenced by waybar.nix. Both emit waybar JSON and degrade
# gracefully when offline.
let
  cfg = config.patrick.home.hyprland;

  publicIp = pkgs.writeShellApplication {
    name = "waybar-public-ip";
    runtimeInputs = with pkgs; [ curl coreutils ];
    text = ''
      ip=$(curl -s -f --max-time 5 https://ifconfig.me 2>/dev/null \
        || curl -s -f --max-time 5 https://icanhazip.com 2>/dev/null \
        || true)
      ip=$(printf '%s' "$ip" | tr -d '[:space:]')
      [ -z "$ip" ] && ip="offline"
      printf '{"text":"%s","tooltip":"public IP"}\n' "$ip"
    '';
  };

  privateIp = pkgs.writeShellApplication {
    name = "waybar-private-ip";
    runtimeInputs = with pkgs; [ iproute2 gawk coreutils ];
    text = ''
      ip=$(ip route get 1.1.1.1 2>/dev/null \
        | awk '{ for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit } }')
      [ -z "$ip" ] && ip="n/a"
      printf '{"text":"%s","tooltip":"private IP"}\n' "$ip"
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [
      publicIp
      privateIp
    ];
  };
}
