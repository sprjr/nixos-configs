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
        background-color: rgba(40, 44, 52, 0.9);
      }
      #clock {
        font-weight: bold;
      }
    '';
  };
}
