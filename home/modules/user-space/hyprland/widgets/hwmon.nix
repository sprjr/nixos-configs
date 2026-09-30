{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# hwstat: JSON-lines hardware stats for the waybar hwmon module and the AGS hardware panel.
let
  cfg = config.patrick.home.hyprland;

  hwstatUnwrapped = pkgs.writers.writePython3Bin "hwstat" {
    libraries = [ pkgs.python3Packages.psutil ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./hwstat.py);

  # Bake the GPU backend in; an explicit --gpu on the command line still overrides it.
  hwstat = pkgs.symlinkJoin {
    name = "hwstat";
    paths = [ hwstatUnwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/hwstat --add-flags "--gpu ${if cfg.gpu == null then "none" else cfg.gpu}"
    '';
  };
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    home.packages = [ hwstat ];
  };
}
