{ config, pkgs, ... }:

{
  virtualisation.docker.enable = true;

  systemd.services.docker-windows = {
    description = "Windows Docker Container";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      TimeoutStopSec = "120"; # 2min

      ExecStartPre = [
        "${pkgs.docker}/bin/docker pull dockurr/windows"
	"${pkgs.docker}/bin/docker rm -f windows"
      ];

      ExecStart = ''
        ${pkgs.docker}/bin/docker run -d \
	  --name windows \
	  --restart always \
	  -e VERSION="11" \
	  --device /dev/kvm \
	  --device /dev/net/tun \
	  --cap-add NET_ADMIN \
	  -p 8006:8006 \
	  -p 3389:3389/tcp \
	  -p 3389:3389/udp \
	  -v /var/lib/docker-windows:/storage \
	  dockurr/windows
      '';

      ExecStop = "${pkgs.docker}/bin/docker stop -t 120 windows";
    };
  };

  system.activationScripts.docker-windows-storage = ''
    mkdir -p /var/lib/docker-windows
  '';

  networking.firewall = {
    allowedTCPPorts = [ 8006 3389 ];
    allowedUDPPorts = [ 3389 ];
  };
}
