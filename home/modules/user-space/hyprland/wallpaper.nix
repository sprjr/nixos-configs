{
  config,
  pkgs,
  lib,
  dark-wallpaper-laptop,
  hyprlandWallpapers ? [ dark-wallpaper-laptop ],
  ...
}:

with lib;

# Declarative rotating wallpapers via awww. The image set is a list of flake=false store paths
# plumbed through extraSpecialArgs (hyprlandWallpapers). awww-daemon runs as a systemd user service
# bound to hyprland-session.target with Restart=on-failure, so an Nvidia startup race self-heals
# instead of leaving the daemon dead (exec-once, its previous home, never restarts). Rotation runs on
# a 30-minute systemd user timer, also bound to hyprland-session.target so it never fires under
# COSMIC/KDE. Super+Shift+W (keybinds.nix) or the `hypr-wallpaper` command rotates immediately.
let
  cfg = config.patrick.home.hyprland;
  wallpapers = map (w: "${w}") hyprlandWallpapers;

  hypr-wallpaper = pkgs.writeShellApplication {
    name = "hypr-wallpaper";
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
      # Retry: awww-daemon may not be ready yet at session start.
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
      hypr-wallpaper
    ];

    # The daemon itself: a resilient replacement for the old exec-once launch. Bound to
    # hyprland-session.target (Hyprland-only) and restarted on failure so a first-frame Nvidia race
    # can't leave it permanently dead.
    systemd.user.services.awww-daemon = {
      Unit = {
        Description = "awww wallpaper daemon";
        PartOf = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };

    systemd.user.services.hypr-wallpaper = {
      Unit = {
        Description = "Rotate the Hyprland wallpaper via awww";
        PartOf = [ "hyprland-session.target" ];
        # Order after the daemon; the script also retries in case the socket isn't up yet.
        After = [ "hyprland-session.target" "awww-daemon.service" ];
        Wants = [ "awww-daemon.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${hypr-wallpaper}/bin/hypr-wallpaper";
      };
    };

    systemd.user.timers.hypr-wallpaper = {
      Unit.Description = "Rotate the Hyprland wallpaper every 30 minutes";
      Timer = {
        # Initial set shortly after the session (and awww-daemon) come up.
        OnActiveSec = "8";
        OnUnitActiveSec = "30min";
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };
}
