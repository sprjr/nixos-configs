{ config, pkgs, ... }:

let
  dataDir = "/var/lib/memtly";
in
{
  sops.secrets."memtly/admin-password" = { };
  sops.secrets."memtly/encryption-key" = { };
  sops.secrets."memtly/encryption-salt" = { };
  sops.secrets."memtly/mariadb-password" = { };
  sops.secrets."memtly/mariadb-root-password" = { };

  sops.templates."memtly-env" = {
    mode = "0400";
    content = ''
      TITLE=Memtly
      DATABASE_TYPE=mariadb
      DATABASE_CONNECTION_STRING=Server=memtly-db;Port=3306;Database=memtly;User=memtly;Password=${
        config.sops.placeholder."memtly/mariadb-password"
      };
      ACCOUNT_ADMIN_PASSWORD=${config.sops.placeholder."memtly/admin-password"}
      SECURITY_ENCRYPTION_KEY=${config.sops.placeholder."memtly/encryption-key"}
      SECURITY_ENCRYPTION_SALT=${config.sops.placeholder."memtly/encryption-salt"}
      LOGGING_GRAYLOG_ENABLED=false
    '';
  };

  sops.templates."memtly-mariadb-env" = {
    mode = "0400";
    content = ''
      MARIADB_ROOT_PASSWORD=${config.sops.placeholder."memtly/mariadb-root-password"}
      MARIADB_DATABASE=memtly
      MARIADB_USER=memtly
      MARIADB_PASSWORD=${config.sops.placeholder."memtly/mariadb-password"}
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir}/config 0750 root root -"
    "d ${dataDir}/thumbnails 0750 root root -"
    "d ${dataDir}/uploads 0750 root root -"
    "d ${dataDir}/custom_resources 0750 root root -"
    "d ${dataDir}/mariadb 0750 root root -"
  ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers.memtly-mariadb = {
      image = "mariadb:11";
      volumes = [
        "${dataDir}/mariadb:/var/lib/mysql"
      ];
      environmentFiles = [
        config.sops.templates."memtly-mariadb-env".path
      ];
      extraOptions = [
        "--health-cmd=healthcheck.sh --connect --innodb_initialized"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=5"
        "--health-start-period=60s"
      ];
    };

    containers.memtly = {
      image = "memtly/memtly:1.0.7.6";
      ports = [ "8080:5000" ];
      volumes = [
        "${dataDir}/config:/app/config"
        "${dataDir}/thumbnails:/app/thumbnails"
        "${dataDir}/uploads:/app/uploads"
        "${dataDir}/custom_resources:/app/custom_resources"
      ];
      environmentFiles = [
        config.sops.templates."memtly-env".path
      ];
      dependsOn = [ "memtly-mariadb" ];
      extraOptions = [
        "--link=memtly-mariadb:memtly-db"
      ];
    };
  };

  # dependsOn only orders unit start; wait for the mariadb healthcheck to pass.
  systemd.services.docker-memtly.serviceConfig.ExecStartPre = [
    (pkgs.writeShellScript "wait-for-memtly-mariadb" ''
      for _ in $(${pkgs.coreutils}/bin/seq 1 24); do
        if [ "$(${config.virtualisation.docker.package}/bin/docker inspect \
          --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' \
          memtly-mariadb 2>/dev/null)" = healthy ]; then
          exit 0
        fi
        ${pkgs.coreutils}/bin/sleep 5
      done
      echo "memtly-mariadb is not healthy after 120s" >&2
      exit 1
    '')
  ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8080 ];
}
