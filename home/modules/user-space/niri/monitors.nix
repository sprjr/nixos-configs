{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Per-host output configuration with mon-local/mon-remote switching via niri msg.
let
  cfg = config.patrick.home.niri;

  # Build niri output config from the structured monitor options.
  mkOutputConfig =
    mon:
    if mon.disable then
      { off = true; }
    else
      let
        parseMode =
          modeStr:
          let
            parts = builtins.match "([0-9]+)x([0-9]+)@([0-9]+)" modeStr;
          in
          if parts != null then
            {
              width = toInt (elemAt parts 0);
              height = toInt (elemAt parts 1);
              refresh = toInt (elemAt parts 2) * 1.0;
            }
          else
            null;
        parsePosition =
          posStr:
          let
            parts = builtins.match "([0-9]+)x([0-9]+)" posStr;
          in
          if parts != null then
            {
              x = toInt (elemAt parts 0);
              y = toInt (elemAt parts 1);
            }
          else
            null;
      in
      { }
      // optionalAttrs (mon.mode != null) { mode = parseMode mon.mode; }
      // optionalAttrs (mon.position != null) { position = parsePosition mon.position; }
      // optionalAttrs (mon.scale != 1.0) { scale = mon.scale; };

  # Generate niri msg commands for runtime monitor switching.
  mkSwitchScript =
    name: monitors:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.niri ];
      text =
        let
          cmds = map (
            mon:
            if mon.disable then
              ''niri msg output "${mon.name}" off''
            else
              let
                modeArg = optionalString (mon.mode != null) '' --mode "${mon.mode}"'';
                scaleArg = optionalString (mon.scale != 1.0) '' --scale ${toString mon.scale}'';
                posArg = optionalString (mon.position != null) (
                  let
                    parts = builtins.match "([0-9]+)x([0-9]+)" mon.position;
                  in
                  if parts != null then
                    " --position ${elemAt parts 0} ${elemAt parts 1}"
                  else
                    ""
                );
              in
              ''niri msg output "${mon.name}" on${modeArg}${scaleArg}${posArg}''
          ) monitors;
        in
        concatStringsSep "\n" cmds;
    };

  monLocal = mkSwitchScript "mon-local" cfg.monitors;
  monRemote = mkSwitchScript "mon-remote" cfg.remoteMonitors;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.outputs = builtins.listToAttrs (
      map (mon: {
        name = mon.name;
        value = mkOutputConfig mon;
      }) cfg.monitors
    );

    home.packages = [ monLocal ] ++ optional (cfg.remoteMonitors != [ ]) monRemote;
  };
}
