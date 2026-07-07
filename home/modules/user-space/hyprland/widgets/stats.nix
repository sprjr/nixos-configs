{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# waybar GPU widget. nvidia via nvidia-smi (nvidia-smi resolves from the system driver
# on PATH), amd via sysfs gpu_busy_percent + hwmon (no hardcoded hwmon path). Only built
# when patrick.home.hyprland.gpu is set; null omits the widget entirely. Exposed on PATH
# as `waybar-gpu`, referenced by waybar.nix.
let
  cfg = config.patrick.home.hyprland;

  nvidiaText = ''
    line=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total \
      --format=csv,noheader,nounits 2>/dev/null | head -n1 || true)
    if [ -z "$line" ]; then
      printf '{"text":"","tooltip":"GPU unavailable"}\n'
      exit 0
    fi
    util=$(printf '%s' "$line" | cut -d, -f1 | tr -d ' ')
    temp=$(printf '%s' "$line" | cut -d, -f2 | tr -d ' ')
    used=$(printf '%s' "$line" | cut -d, -f3 | tr -d ' ')
    total=$(printf '%s' "$line" | cut -d, -f4 | tr -d ' ')
    printf '{"text":"󰢮 %s%% %s°C","tooltip":"VRAM %s/%s MiB"}\n' "$util" "$temp" "$used" "$total"
  '';

  amdText = ''
    util=""
    for f in /sys/class/drm/card*/device/gpu_busy_percent; do
      [ -r "$f" ] && { util=$(cat "$f"); break; }
    done
    temp=""
    for f in /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input; do
      [ -r "$f" ] && { temp=$(($(cat "$f") / 1000)); break; }
    done
    [ -z "$util" ] && { printf '{"text":"","tooltip":"GPU unavailable"}\n'; exit 0; }
    [ -z "$temp" ] && temp="?"
    printf '{"text":"󰢮 %s%% %s°C","tooltip":"AMD GPU"}\n' "$util" "$temp"
  '';

  gpu = pkgs.writeShellApplication {
    name = "waybar-gpu";
    runtimeInputs = with pkgs; [ coreutils ];
    text = if cfg.gpu == "nvidia" then nvidiaText else amdText;
  };
in
{
  config = mkIf (cfg.enable && cfg.gpu != null) {
    home.packages = [ gpu ];
  };
}
