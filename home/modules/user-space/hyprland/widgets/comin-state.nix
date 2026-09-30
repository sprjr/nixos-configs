{
  config,
  pkgs,
  lib,
  osConfig ? { },
  ...
}:

with lib;

# comin-state: comin deployment state for the control center indicator.
let
  cfg = config.patrick.home.hyprland;

  cominState = pkgs.writers.writePython3Bin "comin-state" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./comin-state.py);
in
{
  config = mkIf (cfg.enable && cfg.shell == "native" && (osConfig.services.comin.enable or false)) {
    home.packages = [ cominState ];
  };
}
