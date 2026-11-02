{ config, ... }:

let
  dataDir = "/var/lib/donetick";
in
{
  sops.secrets."donetick/jwt-secret" = { };

  sops.templates."donetick-config" = {
    mode = "0400";
    content = ''
      name: "selfhosted"
      is_done_tick_dot_com: false
      is_user_creation_disabled: false
      database:
        type: "sqlite"
        migration: true
      jwt:
        secret: "${config.sops.placeholder."donetick/jwt-secret"}"
        session_time: 168h
        max_refresh: 1440h
      server:
        port: 2021
        serve_frontend: true
        serve_swagger: true
        public_host: "https://donetick.rawliyosh.com"
      single_circle_instance: true
      realtime:
        enabled: true
        sse_enabled: true
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root -"
    "d ${dataDir}/config 0750 root root -"
  ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers.donetick = {
      image = "donetick/donetick:v0.1.85";
      ports = [ "2021:2021" ];
      volumes = [
        "${dataDir}:/donetick-data"
        "${dataDir}/config:/config"
      ];
      environment = {
        DT_ENV = "selfhosted";
        DT_SQLITE_PATH = "${dataDir}/donetick.db";
      };
      environmentFiles = [ config.sops.templates."donetick-config".path ];
      extraOptions = [
        "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:2021/api/v1/health || exit 1"
        "--health-start-period=1m"
        "--health-timeout=5s"
        "--health-interval=1m"
        "--health-retries=3"
      ];
    };
  };

  systemd.services."docker-donetick".restartTriggers = [ config.sops.templates."donetick-config".path ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2021 ];
}
