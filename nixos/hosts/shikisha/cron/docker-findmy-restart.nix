{ config, pkgs, lib, ... }:

{
  systemd = {
    timers."docker-findmy-restart" = {
      wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = "true";
          Unit = "docker-findmy-restart.service";
        };
      };
    services."docker-findmy-restart" = {
      script = ''
        set -eu
	${pkgs.docker-compose}/bin/docker-compose -f /home/patrick/.docker/findmy/docker-compose.yml restart
      '';
      serviceConfig = {
        Type = "oneshot";
	User = "root";
      };
    };
  };
}
