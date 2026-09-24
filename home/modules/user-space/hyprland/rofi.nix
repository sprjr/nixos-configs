{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      terminal = "ghostty";
      extraConfig = {
        modi = "drun,run,window";
        show-icons = true;
        matching = "fuzzy";
        sort = true;
        sorting-method = "fzf";
        display-drun = "";
        drun-display-format = "{name}";
      };
    };
  };
}
