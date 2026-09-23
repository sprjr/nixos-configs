{ config, lib, ... }:

with lib;

# fuzzel launcher (Super+Space, bound in keybinds.nix). Catppuccin Mocha.
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          terminal = "ghostty";
          layer = "overlay";
          prompt = "\"❯ \"";
          width = 45;
          lines = 8;
        };
        border = {
          width = 2;
          radius = 10;
        };
      };
    };
  };
}
