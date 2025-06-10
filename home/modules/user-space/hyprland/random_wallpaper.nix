{ config, pkgs, home-manager, ... }:

{
  systemd.user.timers.random-wallpaper = {
    wantedBy = [ "timers.target" ];
    timerCOnfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "10min";
      Unit = "random-wallpaper.service";
    };
  };

  systemd.user.services.random-wallpaper = {
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "random-wallpaper" ''
        ${pkgs.findutils}/bin/find ~/Nextcloud/Photos/Wallpapers/Desktop -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | \
	${pkgs.coreutils}/bin/shuf -n 1 | \
	while read -r wallpaper; do
	  ${pkgs.hyprland}/bin/hyprctl hyprpaper unload all
	  ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$wallpaper"
	  ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ",$wallpaper"
	done
      ''}";
    };
  };
}
