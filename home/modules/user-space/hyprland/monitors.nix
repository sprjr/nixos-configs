{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Per-host monitor descriptors with mon-local/mon-remote switching.
let
  cfg = config.patrick.home.hyprland;

  # Runtime `hyprctl keyword monitor` can't take the ",preferred,auto,auto" catch-all
  # (empty output name), so only named descriptors are re-applied.
  named = filter (m: !(hasPrefix "," m)) ;
  batchOf = ms: concatStringsSep " ; " (map (m: "keyword monitor ${m}") (named ms));

  mkSwitcher =
    name: descriptors:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ config.wayland.windowManager.hyprland.package ];
      text = ''
        if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          for d in /run/user/"$(id -u)"/hypr/*/; do
            [ -S "''${d}.socket.sock" ] && {
              export HYPRLAND_INSTANCE_SIGNATURE
              HYPRLAND_INSTANCE_SIGNATURE=$(basename "$(dirname "$d")")
              break
            }
          done
        fi

        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          hyprctl --batch "${batchOf descriptors}"
        else
          echo "${name}: no running Hyprland instance found" >&2
          exit 1
        fi
      '';
    };

  monLocal = mkSwitcher "mon-local" cfg.monitors;
  monRemote = mkSwitcher "mon-remote" cfg.remoteMonitors;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.monitor = cfg.monitors;

    home.packages = [ monLocal ] ++ optional (cfg.remoteMonitors != [ ]) monRemote;
  };
}
