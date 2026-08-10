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
    ];
  };
}
