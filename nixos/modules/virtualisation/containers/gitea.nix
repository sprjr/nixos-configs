# Auto-generated using compose2nix v0.1.7.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
#    dockerCompat = true;
#    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
#      dns_enabled = true;
#    };
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."gitea" = {
    image = "gitea/gitea:1.21.7";
    environment = {
      GITEA__database__DB_TYPE = "postgres";
      GITEA__database__HOST = "db:5432";
      GITEA__database__NAME = "gitea";
      GITEA__database__PASSWD = "pVoV68ui28V9X2vY9Ji9gLhmw4o3A2BJRWH4cK4JhaifcCjX2d9XRBEugJ4fNSQS";
      GITEA__database__USER = "gitea";
      USER_GID = "1000";
      USER_UID = "1000";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/etc/timezone:/etc/timezone:ro"
      "/home/patrick/opt/containers_appdata/gitea:/data:rw"
    ];
    ports = [
      "3000:3000/tcp"
      "222:22/tcp"
    ];
    dependsOn = [
      "giteaproject-db"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=server"
      "--network=giteaproject-gitea"
    ];
  };
  systemd.services."podman-gitea" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    startLimitIntervalSec = 0;
    after = [
      "podman-network-giteaproject-gitea.service"
    ];
    requires = [
      "podman-network-giteaproject-gitea.service"
    ];
    partOf = [
      "podman-compose-giteaproject-root.target"
    ];
    unitConfig.UpheldBy = [
      "podman-giteaproject-db.service"
    ];
    wantedBy = [
      "podman-compose-giteaproject-root.target"
    ];
  };
  virtualisation.oci-containers.containers."giteaproject-db" = {
    image = "postgres:14";
    environment = {
      POSTGRES_DB = "gitea";
      POSTGRES_PASSWORD = "pVoV68ui28V9X2vY9Ji9gLhmw4o3A2BJRWH4cK4JhaifcCjX2d9XRBEugJ4fNSQS";
      POSTGRES_USER = "gitea";
    };
    volumes = [
      "/home/patrick/opt/containers_appdata/gitea/postgres:/var/lib/postgresql/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=db"
      "--network=giteaproject-gitea"
    ];
  };
  systemd.services."podman-giteaproject-db" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    startLimitIntervalSec = 0;
    after = [
      "podman-network-giteaproject-gitea.service"
    ];
    requires = [
      "podman-network-giteaproject-gitea.service"
    ];
    partOf = [
      "podman-compose-giteaproject-root.target"
    ];
    wantedBy = [
      "podman-compose-giteaproject-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-giteaproject-gitea" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.podman}/bin/podman network rm -f giteaproject-gitea";
    };
    script = ''
      podman network inspect giteaproject-gitea || podman network create giteaproject-gitea --opt isolate=true
    '';
    partOf = [ "podman-compose-giteaproject-root.target" ];
    wantedBy = [ "podman-compose-giteaproject-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-giteaproject-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
