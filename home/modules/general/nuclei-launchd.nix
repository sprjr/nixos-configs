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
    };
  };
}
