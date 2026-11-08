{ config, lib, ... }:

with lib;

let
  cfg = config.patrick.home.niri;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.window-rules = [
      {
        matches = [{ app-id = "^weather-forecast$"; }];
        open-floating = true;
        default-column-width.fixed = 500;
      }
      {
        matches = [{ app-id = "^steam$"; }];
        open-on-workspace = "1";
      }
      {
        matches = [{ app-id = "^com\\.mitchellh\\.ghostty$"; }];
        open-on-workspace = "2";
      }
      {
        matches = [{ app-id = "^signal$"; }];
        open-on-workspace = "3";
      }
      {
        matches = [{ app-id = "^legcord$"; }];
        open-on-workspace = "3";
      }
      {
        matches = [{ app-id = "^firefox$"; }];
        open-on-workspace = "3";
      }
    ];
  };
}
