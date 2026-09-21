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
      DATABASE_URL=postgresql://zipline:${
        config.sops.placeholder."zipline/postgres-password"
      }@zipline-db:5432/zipline
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
        "--health-cmd=pg_isready -U zipline"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=5"
      ];
    };

    containers.zipline = {
      image = "ghcr.io/diced/zipline:latest";
      ports = [ "3221:3000" ];
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
        "--link=zipline-postgres:zipline-db"
      ];
    };
  };

  # dependsOn only orders unit start; wait for the postgres healthcheck to pass.
  systemd.services.docker-zipline.serviceConfig.ExecStartPre = [
    (pkgs.writeShellScript "wait-for-zipline-postgres" ''
      for _ in $(${pkgs.coreutils}/bin/seq 1 24); do
        if [ "$(${config.virtualisation.docker.package}/bin/docker inspect \
          --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' \
          zipline-postgres 2>/dev/null)" = healthy ]; then
          exit 0
        fi
        ${pkgs.coreutils}/bin/sleep 5
      done
      echo "zipline-postgres is not healthy after 120s" >&2
      exit 1
    '')
  ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3221 ];
}
