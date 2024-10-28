{ config, pkgs, home-manager, lib, ... }:

{
  programs.zellij = {
  enable = true;
    settings = {
      theme = "nord";
      themes.nord = {
        fg = "#D8DEE9";
        bg = "#2E3440";
        black = "#3B4252";
        red = "#BF616A";
        green = "#A3BE8C";
        yellow = "#EBCB8B";
        blue = "#81A1C1";
        magenta = "#B48EAD";
        cyan = "#88C0D0";
        white = "#E5E9F0";
        orange = "#D08770";
      };
      layout.default = "layout { pane { split_direction \"Horizontal\" } pane { split_direction \"Vertical\" pane { } pane { command \"btop\" } } }";
    };
  };
}
