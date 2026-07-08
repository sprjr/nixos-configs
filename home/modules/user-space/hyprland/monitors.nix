{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Per-host monitor descriptors via the `monitors` option. Default is a single
# ",preferred,auto,auto" auto-fallback that adapts to any laptop panel or hotplugged
# output. seanix passes its exact three-monitor layout (translated from
# home/modules/user-space/monitor-switch.nix) and keeps the fallback line last.
#
# Workspaces are intentionally NOT bound to outputs — they follow the focused monitor,
# so behavior is identical on a single-monitor laptop and on seanix.
#
# mon-local / mon-remote replace the KDE-only kscreen-doctor scripts (remon/lomon aliases):
# inside a Hyprland session they apply the descriptors via hyprctl; outside one they fall
# back to the existing ~/.local/bin/switch-*.sh (kscreen) so the same command works in KDE too.
let
  cfg = config.patrick.home.hyprland;

  # Runtime `hyprctl keyword monitor` can't take the ",preferred,auto,auto" catch-all
  # (empty output name), so only named descriptors are re-applied.
  named = filter (m: !(hasPrefix "," m)) ;
  batchOf = ms: concatStringsSep " ; " (map (m: "keyword monitor ${m}") (named ms));

  mkSwitcher =
    name: descriptors: kdeFallback:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ config.wayland.windowManager.hyprland.package ];
      text = ''
        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          hyprctl --batch "${batchOf descriptors}"
        elif [ -x "$HOME/.local/bin/${kdeFallback}" ]; then
          "$HOME/.local/bin/${kdeFallback}"
        else
          echo "${name}: not in a Hyprland session and no ~/.local/bin/${kdeFallback} fallback" >&2
          exit 1
        fi
      '';
    };

  monLocal = mkSwitcher "mon-local" cfg.monitors "switch-local.sh";
  monRemote = mkSwitcher "mon-remote" cfg.remoteMonitors "switch-remote.sh";
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.monitor = cfg.monitors;

    home.packages = [ monLocal ] ++ optional (cfg.remoteMonitors != [ ]) monRemote;
  };
}
