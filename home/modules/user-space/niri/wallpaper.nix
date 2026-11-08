{
  config,
  pkgs,
  lib,
  dark-wallpaper-laptop,
  hyprlandWallpapers ? [ dark-wallpaper-laptop ],
  ...
}:

with lib;

# Rotating wallpapers via awww with systemd restart resilience.
let
  cfg = config.patrick.home.niri;
  wallpapers = map (w: "${w}") hyprlandWallpapers;

  niri-wallpaper = pkgs.writeShellApplication {
    name = "niri-wallpaper";
    runtimeInputs = [
      pkgs.awww
      pkgs.coreutils
    ];
    text = ''
      wallpapers=(${concatStringsSep " " (map (w: ''"${w}"'') wallpapers)})
      if [ ''${#wallpapers[@]} -eq 0 ]; then
        exit 0
      fi
      pick="''${wallpapers[RANDOM % ''${#wallpapers[@]}]}"
      for _ in 1 2 3 4 5; do
        if awww img "$pick" --transition-type none; then
          exit 0
        fi
        sleep 1
      done
      exit 1
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.awww
      niri-wallpaper
    ];

    systemd.user.services.awww-daemon = {
      Unit = {
        Description = "awww wallpaper daemon";
        PartOf = [ "niri-session.target" ];
        After = [ "niri-session.target" ];
        Wants = [ "niri-wallpaper.service" ];
      };
      Service = {
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "niri-session.target" ];
    };

    systemd.user.services.niri-wallpaper = {
      Unit = {
        Description = "Rotate the Niri wallpaper via awww";
        PartOf = [ "niri-session.target" ];
        After = [ "niri-session.target" "awww-daemon.service" ];
        Wants = [ "awww-daemon.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${niri-wallpaper}/bin/niri-wallpaper";
      };
    };

    systemd.user.timers.niri-wallpaper = {
      Unit.Description = "Rotate the Niri wallpaper every 30 minutes";
      Timer = {
        OnActiveSec = "8";
        OnUnitActiveSec = "30min";
      };
      Install.WantedBy = [ "niri-session.target" ];
    };
  };
}
