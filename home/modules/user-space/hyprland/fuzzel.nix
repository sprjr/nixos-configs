{ config, lib, ... }:

with lib;

# fuzzel launcher (Super+Space, bound in keybinds.nix). Catppuccin Mocha.
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf cfg.enable {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          terminal = "ghostty";
          layer = "overlay";
          font = "JetBrainsMono Nerd Font:size=12";
          prompt = "\"❯ \"";
          width = 45;
          lines = 8;
        };
        colors = {
          background = "1e1e2eee";
          text = "cdd6f4ff";
          match = "f38ba8ff";
          selection = "585b70ff";
          selection-text = "cdd6f4ff";
          selection-match = "f38ba8ff";
          border = "b4befeff";
        };
        border = {
          width = 2;
          radius = 10;
        };
      };
    };
  };
}
