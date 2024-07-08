{ config, pkgs, ... }:

{
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    9000
    514
  ];

  virtualisation.oci-containers = {
    containers = {
      mongodb = {
        image = "docker.io/mongo:6.0.9";
        autoStart = true;
        volumes = [
         "/home/patrick/.docker/appdata/mongo:/data/db"
          "/etc/localtime:/etc/localtime:ro"
        ];
        extraOptions = [
          "--network=host"
        ];
      };
      opensearch = {
        image = "docker.io/opensearchproject/opensearch:2.3.0";
        autoStart = true;
        environment = {
          "discovery.type" = "single-node";
          "network.host" = "127.0.0.1";
          "plugins.security.disabled" = "true";
        };
        volumes = [
          "/home/patrick/.docker/appdata/graylog/opensearch:/usr/share/opensearch/data"
          "/etc/localtime:/etc/localtime:ro"
        ];
        extraOptions = [
          "--network=host"
        ];
      };
      graylog = {
        image = "docker.io/graylog/graylog:5.2";
        autoStart = true;
        environment = {
          GRAYLOG_IS_MASTER = "true";
#          GRAYLOG_PASSWORD_SECRET = builtins.readFile /opt/graylog/secret.txt;
#          GRAYLOG_ROOT_PASSWORD_SHA2 = builtins.readFile /opt/graylog/pass.txt;
#          GRAYLOG_HTTP_EXTERNAL_URI = "http://nix-nvidia.tailscale:9000/";
          GRAYLOG_ELASTICSEARCH_HOSTS = "http://localhost:9200";
          GRAYLOG_MONGODB_URI = "mongodb://localhost:27017/graylog";
        };
        #environmentFiles = [
         #/opt/graylog/graylog.env
        #];
        volumes = [
          "/home/patrick/.docker/appdata/graylog/data:/usr/share/graylog/data/data"
          "/home/patrick/.docker/appdata/graylog/journal:/usr/share/graylog/data/journal"
          "/etc/localtime:/etc/localtime:ro"
        ];
        extraOptions = [
          "--network=host"
        ];
      };
    };
  };
}
