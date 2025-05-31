{ config, pkgs, home-manager, lib, ... }:

{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    settings = {
        mainBar = {
	  layer = "top";
	  position = "top";
	  height = 30;
	  output = [
	    "eDP-1"
	    #"HDMI-A-1"
	  ];
	  modules-left = [
	    "sway/workspaces"
	    "sway/mode"
	    "wlr/taskbar"
	  ];
	  modules-center = [
	    "clock"
	  ];
	  modules-right = [
	    "battery"
	    "modules"
	    "mpd"
	    "network"
	   #"pulseaudio"
	    "temperature"
	    "tray"
	  ];

          "clock" = {
	    format = "{:%Y-%m-%d %H:%M:%S}";
	  };

	  "sway/workspaces" = {
	    disable-scroll = true;
	    all-outputs = true;
	  };
	};
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", sans-serif;
	font-size: 13px;
	color: #ffffff;
      }

      window#waybar {
        background-color: #2E3440;
	border-bottom: 1px solid #4C566A;
      }

      #clock {
        padding: 0 10px;
	color: #ECEFF4;
	background-color: #3B4252;
	border-radius: 6px;
	margin: 2px;
        font-weight: bold;
      }

      #battery.charging {
        color: #A3BE8C;
      }

      #battery.warning {
        color: #EBCB8B;
      }

      #battery.critical {
        color: #BF616A;
      }

      #workspaces button.focused {
        background-color: #5E81AC;
	color: #ECEFF4;
      }

      #workspaces button {
        padding: 0 6px;
	color: #D8DEE9;
	background-color: #2E3440;
      }
    '';
  };
}
