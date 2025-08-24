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
        color: #2E3440;
	background-color: #A3BE8C;
      }

      #battery.warning {
        color: #2E3440;
	background-color: #EBCB8B;
      }

      #battery.critical {
        color: #2E3440;
	background-color: #BF616A;
      }

      #clock,
      #battery,
      #network,
      #temperature,
      #mpd,
      #tray {
        background-color: #3B4252;
	padding: 4px 10px;
	margin: 2px;
	border-radius: 8px;
        transition: background-color 0.2s ease;
      }

      #clock:hover,
      #battery:hover,
      #network:hover,
      #temperature:hover,
      #mpd:hover,
      #tray:hover {
        background-color: #434C5E;
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

      #mpd.playing {
        background-color: #BF616A;
	color: #2E3440;
      }

      #network.disconnected {
        background-color: #BF616A;
	color: #2E3440;
      }
    '';
  };
}
