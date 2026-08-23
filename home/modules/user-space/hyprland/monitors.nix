{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Per-host monitor descriptors, plus (when cfg.streaming.enable) a persistent headless
# output and DPMS/workspace-migration mon-remote/mon-local, in place of enabling/disabling
# outputs -- testing whether that avoids the aquamarine SEGV cfg.debugLogging chases.
let
  cfg = config.patrick.home.hyprland;
  streamCfg = cfg.streaming;

  hyprPkg = config.wayland.windowManager.hyprland.package;

  # `uwsm finalize` (exec-once) already exports this into the session; this loop is a
  # fallback for scripts invoked outside that env (Sunshine's prep-cmd, SSH).
  findInstance = ''
    if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      for d in /run/user/"$(id -u)"/hypr/*/; do
        [ -S "''${d}.socket.sock" ] && {
          export HYPRLAND_INSTANCE_SIGNATURE
          HYPRLAND_INSTANCE_SIGNATURE=$(basename "$d")
          break
        }
      done
    fi
    if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      echo "$0: no running Hyprland instance found" >&2
      exit 1
    fi
  '';

  runtimeNameFile = ''"''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr-streaming-output"'';

  # Runtime `hyprctl keyword monitor` can't take the ",preferred,auto,auto" catch-all
  # (empty output name), so only named descriptors are re-applied.
  named = filter (m: !(hasPrefix "," m));
  batchOf = ms: concatStringsSep " ; " (map (m: "keyword monitor ${m}") (named ms));

  # Non-streaming fallback: re-applies `monitors` verbatim (original enable/disable mechanism).
  monLocalStatic = pkgs.writeShellApplication {
    name = "mon-local";
    runtimeInputs = [ hyprPkg ];
    text = ''
      ${findInstance}
      hyprctl --batch "${batchOf cfg.monitors}"
    '';
  };

  # Idempotent, never destroys the output. Hyprland doesn't guarantee "HEADLESS-1" as the
  # first name handed out, so the assigned name is recorded for mon-remote to read.
  headlessOutputSetup = pkgs.writeShellApplication {
    name = "hyprland-headless-output-setup";
    runtimeInputs = [
      hyprPkg
      pkgs.jq
    ];
    text = ''
      ${findInstance}
      existing=$(hyprctl monitors all -j | jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name' | head -n1)
      if [ -z "$existing" ]; then
        hyprctl output create headless
        existing=$(hyprctl monitors all -j | jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name' | head -n1)
      fi
      if [ -z "$existing" ]; then
        echo "hyprland-headless-output-setup: failed to create/find a HEADLESS-* output" >&2
        exit 1
      fi
      hyprctl keyword monitor "$existing,${streamCfg.resolution},auto,1"
      echo "$existing" > ${runtimeNameFile}
    '';
  };

  monRemoteStreaming = pkgs.writeShellApplication {
    name = "mon-remote";
    runtimeInputs = [ hyprPkg ];
    text = ''
      ${findInstance}
      headless=$(cat ${runtimeNameFile} 2>/dev/null || true)
      if [ -z "$headless" ]; then
        echo "mon-remote: no headless output recorded -- is hyprland-headless-output.service running?" >&2
        exit 1
      fi
      ${concatMapStringsSep "\n      " (
        ws: ''hyprctl dispatch moveworkspacetomonitor ${toString ws} "$headless"''
      ) streamCfg.workspaces}
      ${concatMapStringsSep "\n      " (o: "hyprctl dispatch dpms off ${o}") streamCfg.physicalOutputs}
    '';
  };

  monLocalStreaming = pkgs.writeShellApplication {
    name = "mon-local";
    runtimeInputs = [ hyprPkg ];
    text = ''
      ${findInstance}
      ${concatMapStringsSep "\n      " (o: "hyprctl dispatch dpms on ${o}") streamCfg.physicalOutputs}
      ${concatMapStringsSep "\n      " (
        ws: "hyprctl dispatch moveworkspacetomonitor ${toString ws} ${streamCfg.primaryOutput}"
      ) streamCfg.workspaces}
    '';
  };
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.monitor = cfg.monitors;

    home.packages = if streamCfg.enable then [ monRemoteStreaming monLocalStreaming ] else [ monLocalStatic ];

    systemd.user.services.hyprland-headless-output = mkIf streamCfg.enable {
      Unit = {
        Description = "Create the persistent headless output used by mon-remote/Sunshine";
        PartOf = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = getExe headlessOutputSetup;
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };
}
