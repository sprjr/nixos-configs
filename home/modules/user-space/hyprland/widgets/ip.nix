{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Public IP waybar module.
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

in
{
  config = mkIf cfg.enable {
    home.packages = [
      publicIp
    ];
  };
}
