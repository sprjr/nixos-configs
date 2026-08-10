{
  config,
  pkgs,
  lib,
  dark-wallpaper-laptop,
  ...
}:

with lib;

# swaylock-effects: Catppuccin Mocha, blur, clock/date. Replaces hyprlock.
let
  cfg = config.patrick.home.niri;
in
{
  config = mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        clock = true;
        datestr = "%A, %B %d %Y";
        timestr = "%I:%M";
        image = "${dark-wallpaper-laptop}";
        effect-blur = "7x5";
        indicator = true;
        indicator-radius = 100;
        indicator-thickness = 7;
        font = "JetBrainsMono Nerd Font";
        font-size = 24;

        # Catppuccin Mocha colors (matching hyprlock theme)
        inside-color = "1e1e2e";
        ring-color = "b4befe";
        text-color = "cdd6f4";
        key-hl-color = "a6e3a1";
        bs-hl-color = "f38ba8";
        inside-ver-color = "1e1e2e";
        ring-ver-color = "89b4fa";
        text-ver-color = "cdd6f4";
        inside-wrong-color = "1e1e2e";
        ring-wrong-color = "f38ba8";
        text-wrong-color = "f38ba8";
        inside-clear-color = "1e1e2e";
        ring-clear-color = "a6e3a1";
        text-clear-color = "cdd6f4";
      };
    };
  };
}
