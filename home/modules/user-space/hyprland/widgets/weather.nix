{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# waybar weather module. Reads the COSMIC lat/lon sops secrets and queries wttr.in
# (matching the existing shell alias). Emits waybar JSON; degrades to an "unavailable"
# state instead of erroring when the network/API is down. Exposed on PATH as
# `waybar-weather` and referenced by waybar.nix.
let
  cfg = config.patrick.home.hyprland;
  latPath = config.sops.secrets."cosmic/latitude".path;
  lonPath = config.sops.secrets."cosmic/longitude".path;

  weather = pkgs.writeShellApplication {
    name = "waybar-weather";
    runtimeInputs = with pkgs; [ curl coreutils ];
    text = ''
      lat=$(tr -d '[:space:]' < ${latPath})
      lon=$(tr -d '[:space:]' < ${lonPath})

      out=$(curl -s -f --max-time 10 "wttr.in/$lat,$lon?format=%c+%t" 2>/dev/null || true)
      out=$(printf '%s' "$out" | tr -d '\n')

      if [ -z "$out" ]; then
        printf '{"text":"","tooltip":"weather unavailable"}\n'
        exit 0
      fi

      printf '{"text":"%s","tooltip":"%s"}\n' "$out" "$out"
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [ weather ];
  };
}
