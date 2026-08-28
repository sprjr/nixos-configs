{ config, pkgs, ... }:

let
  dataDir = "/var/lib/zipline";
in
{
  sops.secrets."zipline/postgres-password" = { };
  sops.secrets."zipline/core-secret" = { };

  sops.templates."zipline-env" = {
    mode = "0400";
    content = ''
      DATABASE_URL=postgresql://zipline:${config.sops.placeholder."zipline/postgres-password"}@zipline-postgres:5432/zipline
      CORE_SECRET=${config.sops.placeholder."zipline/core-secret"}
    '';
  };

  sops.templates."zipline-postgres-env" = {
    mode = "0400";
    content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."zipline/postgres-password"}
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir}/uploads 0755 root root -"
    "d ${dataDir}/public 0755 root root -"
    "d ${dataDir}/themes 0755 root root -"
    "d ${dataDir}/pgdata 0755 root root -"
  ];

  systemd.services.zipline-network-init = {
    description = "Create Zipline Docker network";
    wantedBy = [ "multi-user.target" ];
    before = [
      "docker-zipline.service"
      "docker-zipline-postgres.service"
    ];
    after = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.docker ];
    script = ''
      if ! docker network inspect zipline-net >/dev/null 2>&1; then
        docker network create zipline-net
      fi
    '';
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.zipline-postgres = {
      image = "postgres:16";
      volumes = [
        "${dataDir}/pgdata:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_USER = "zipline";
        POSTGRES_DB = "zipline";
      };
      environmentFiles = [
        config.sops.templates."zipline-postgres-env".path
      ];
      extraOptions = [
        "--network=zipline-net"
        "--health-cmd=pg_isready -U zipline"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=5"
      ];
    };

    containers.zipline = {
      image = "ghcr.io/diced/zipline:latest";
      ports = [ "3001:3000" ];
      volumes = [
        "${dataDir}/uploads:/zipline/uploads"
        "${dataDir}/public:/zipline/public"
        "${dataDir}/themes:/zipline/themes"
      ];
      environment = {
        CORE_PORT = "3000";
        CORE_HOSTNAME = "0.0.0.0";
        DATASOURCE_TYPE = "local";
        DATASOURCE_LOCAL_DIRECTORY = "./uploads";
      };
      environmentFiles = [
        config.sops.templates."zipline-env".path
      ];
      dependsOn = [ "zipline-postgres" ];
      extraOptions = [
        "--network=zipline-net"
      ];
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3001 ];
}
