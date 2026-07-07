{ config, lib, ... }:

with lib;

# Per-host monitor descriptors via the `monitors` option. Default is a single
# ",preferred,auto,auto" auto-fallback that adapts to any laptop panel or hotplugged
# output. seanix passes its exact three-monitor layout (translated from
# home/modules/user-space/monitor-switch.nix) and keeps the fallback line last.
#
# Workspaces are intentionally NOT bound to outputs — they follow the focused monitor,
# so behavior is identical on a single-monitor laptop and on seanix.
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.monitor = cfg.monitors;
  };
}
