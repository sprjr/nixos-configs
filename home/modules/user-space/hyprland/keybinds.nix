{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.patrick.home.hyprland;

  data = import ./keybind-data.nix { inherit pkgs cfg; };

  # Widest key string, so the plain-text sheet's keys column lines up.
  keyWidth = foldl' (a: g: foldl' (b: x: max b (stringLength x.keys)) a g.binds) 0 data.groups;
  padKey = s: s + fixedWidthString (keyWidth - stringLength s) " " "";

  hyprshort = pkgs.writeShellApplication {
    name = "hyprshort";
    text = ''
      cat <<'EOF'
      Hyprland keybindings (mainMod = SUPER)

      ${concatMapStringsSep "\n\n" (g:
        g.title + "\n" + concatMapStringsSep "\n" (b: "  ${padKey b.keys}  ${b.desc}") g.binds
      ) data.groups}
      EOF
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [ hyprshort ];

    # All binds are declared in keybind-data.nix alongside their cheat-sheet entries.
    wayland.windowManager.hyprland.settings.bind = map data.toBind data.binds;

    wayland.windowManager.hyprland.submaps.resize.settings.bind = map data.toBind [
      { keys = "h"; dsp = "hl.dsp.window.resize({ x = -40, y = 0, relative = true })"; opts = { repeating = true; }; }
      { keys = "l"; dsp = "hl.dsp.window.resize({ x = 40, y = 0, relative = true })"; opts = { repeating = true; }; }
      { keys = "k"; dsp = "hl.dsp.window.resize({ x = 0, y = -40, relative = true })"; opts = { repeating = true; }; }
      { keys = "j"; dsp = "hl.dsp.window.resize({ x = 0, y = 40, relative = true })"; opts = { repeating = true; }; }
      { keys = "Escape"; dsp = ''hl.dsp.submap("reset")''; }
      { keys = "Return"; dsp = ''hl.dsp.submap("reset")''; }
    ];
  };
}
