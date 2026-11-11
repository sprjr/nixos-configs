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
    wayland.windowManager.hyprland.settings = {
      inherit (data.binds) bind bindel bindl bindm;
    };

    wayland.windowManager.hyprland.submaps.resize.settings = {
      binde = [
        ", h, resizeactive, -40 0"
        ", l, resizeactive, 40 0"
        ", k, resizeactive, 0 -40"
        ", j, resizeactive, 0 40"
      ];
      bind = [
        ", Escape, submap, reset"
        ", Return, submap, reset"
      ];
    };
  };
}
