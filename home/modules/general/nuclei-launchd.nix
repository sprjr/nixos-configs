{ config, pkgs, ... }:

{
  launchd.agents.nuclei-templates = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.nuclei}/bin/nuclei"
        "-ut"
        "-ud"
        "${config.home.homeDirectory}/nuclei-templates"
      ];
      StartCalendarInterval = [ { Hour = 9; Minute = 0; } ];
      # Seed templates on first load
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/nuclei-templates.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/nuclei-templates.log";
    };
  };
}
