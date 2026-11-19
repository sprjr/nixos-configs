{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Per-host monitor descriptors, plus the persistent headless output and mon-remote/mon-local.
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

  dpms = action: output: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\", monitor = \"${output}\" })'";

  runtimeNameFile = ''"''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr-streaming-output"'';

  # Pinned so Sunshine's output_name can reference it.
  headlessName = "HEADLESS-STREAM";

  # The ",preferred,auto,auto" catch-all (empty output name) is not re-applied at runtime,
  # so only named descriptors are.
  named = filter (m: !(hasPrefix "," m));

  # "output,mode,position,scale" or "output,disable" -> hl.monitor spec.
  toMonitorSpec =
    m:
    let
      f = splitString "," m;
    in
    if elemAt f 1 == "disable" then
      {
        output = elemAt f 0;
        disabled = true;
      }
    else
      {
        output = elemAt f 0;
        mode = elemAt f 1;
        position = elemAt f 2;
        scale = elemAt f 3;
      };

  # Lua chunk for `hyprctl eval` re-applying the named descriptors.
  evalMonitors =
    ms:
    concatMapStringsSep " " (m: "hl.monitor(${generators.toLua { multiline = false; } (toMonitorSpec m)})") (
      named ms
    );

  # NVIDIA EINVAL commit loop on 0.57 (aquamarine #472); drop once nixpkgs ships aquamarine PR #477.
  # One output at a time (disabling all drops to FALLBACK); re-enable needs explicit disabled = false.
  toLuaLine = generators.toLua { multiline = false; };
  loopSpecs = filter (s: elem s.output cfg.commitLoopOutputs) (map toMonitorSpec (named cfg.monitors));
  cycleOutput = i: s: ''
    hl.timer(function() hl.monitor(${toLuaLine { output = s.output; disabled = true; }}) end, { timeout = ${toString (1000 + i * 1000)}, type = "oneshot" })
    hl.timer(function() hl.monitor(${toLuaLine (s // { disabled = false; })}) end, { timeout = ${toString (1500 + i * 1000)}, type = "oneshot" })
  '';
  commitLoopWorkaround = ''
    hl.on("hyprland.start", function()
    ${concatStrings (imap0 cycleOutput loopSpecs)}end)
  '';

  # Non-streaming fallback: re-applies `monitors` verbatim (original enable/disable mechanism).
  monLocalStatic = pkgs.writeShellApplication {
    name = "mon-local";
    runtimeInputs = [ hyprPkg ];
    text = ''
      ${findInstance}
      hyprctl eval ${escapeShellArg (evalMonitors cfg.monitors)}
    '';
  };

  # Idempotent, never destroys the output. The name is pinned via headlessName so
  # Sunshine's static output_name resolves to it.
  headlessOutputSetup = pkgs.writeShellApplication {
    name = "hyprland-headless-output-setup";
    runtimeInputs = [
      hyprPkg
      pkgs.jq
    ];
    text = ''
      ${findInstance}
      existing=$(hyprctl monitors all -j | jq -r --arg n ${escapeShellArg headlessName} '.[] | select(.name == $n) | .name' | head -n1)
      if [ -z "$existing" ]; then
        hyprctl output create headless ${headlessName}
        existing=$(hyprctl monitors all -j | jq -r --arg n ${escapeShellArg headlessName} '.[] | select(.name == $n) | .name' | head -n1)
      fi
      if [ -z "$existing" ]; then
        echo "hyprland-headless-output-setup: failed to create/find ${headlessName}" >&2
        exit 1
      fi
      hyprctl eval "hl.monitor({ output = \"$existing\", mode = \"${streamCfg.resolution}\", position = \"auto\", scale = 1 })"
      echo "$existing" > ${runtimeNameFile}
    '';
  };

  monRemoteStreaming = pkgs.writeShellApplication {
    name = "mon-remote";
    runtimeInputs = [
      hyprPkg
      pkgs.jq
    ];
    text = ''
      ${findInstance}
      headless=$(cat ${runtimeNameFile} 2>/dev/null || true)
      if [ -z "$headless" ]; then
        echo "mon-remote: no headless output recorded -- is hyprland-headless-output.service running?" >&2
        exit 1
      fi
      hyprctl dispatch "hl.dsp.dpms({ action = \"on\", monitor = \"$headless\" })" || true
      hyprctl dispatch "hl.dsp.focus({ monitor = \"$headless\" })"
      hyprctl dispatch 'hl.dsp.focus({ workspace = ${toString streamCfg.workspace} })'
      ${optionalString streamCfg.bigPicture ''
        # Re-home Big Picture off the workspace-1 steam rule.
        hyprctl dispatch 'hl.dsp.exec_cmd("steam -bigpicture")'
        for _ in $(seq 1 60); do
          hyprctl dispatch 'hl.dsp.window.move({ window = "class:^(steam)$", workspace = ${toString streamCfg.workspace}, follow = false })' >/dev/null 2>&1 || true
          hyprctl clients -j | jq -e '.[] | select(.class == "steam" and .workspace.id == ${toString streamCfg.workspace})' >/dev/null && break
          sleep 0.25
        done
      ''}
      ${concatMapStringsSep "\n      " (dpms "off") streamCfg.physicalOutputs}
    '';
  };

  monLocalStreaming = pkgs.writeShellApplication {
    name = "mon-local";
    runtimeInputs = [ hyprPkg ];
    text = ''
      ${findInstance}
      headless=$(cat ${runtimeNameFile} 2>/dev/null || true)
      ${concatMapStringsSep "\n      " (dpms "on") streamCfg.physicalOutputs}
      ${optionalString (
        streamCfg.primaryOutput != ""
      ) "hyprctl dispatch 'hl.dsp.focus({ monitor = \"${streamCfg.primaryOutput}\" })'"}
      if [ -n "$headless" ]; then
        hyprctl dispatch "hl.dsp.dpms({ action = \"off\", monitor = \"$headless\" })" || true
      fi
    '';
  };
in
{
  options.patrick.home.hyprland.commitLoopOutputs = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = ''
      Named outputs cycled off/on once at startup to clear the 0.57 NVIDIA EINVAL commit loop
      (aquamarine #472). Each must have a descriptor in `monitors`.
    '';
    example = [ "DP-1" ];
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.monitor = map toMonitorSpec cfg.monitors;
    wayland.windowManager.hyprland.extraConfig = mkIf (loopSpecs != [ ]) commitLoopWorkaround;

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
