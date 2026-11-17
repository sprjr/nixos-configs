{ config, pkgs, ... }:

{
  sops.secrets."atticd/env-file" = {
    restartUnits = [ "atticd.service" ];
  };
  networking.firewall.interfaces = {
    tailscale0.allowedTCPPorts = [ 8089 ];
    netbird0.allowedTCPPorts = [ 8089 ];
    br0.allowedTCPPorts = [ 8089 ];
    enp1s0.allowedTCPPorts = [ 8089 ];
  };

  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets."atticd/env-file".path;
    settings = {
      listen = "[::]:8089";
      api-endpoint = "http://shikisha:8089/";
      database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "90 days";
      };
      jwt = { };
      # Warning: changing chunking values breaks deduplication for existing NARs.
      chunking = {
        nar-size-threshold = 64 * 1024;
        min-size = 16 * 1024;
        avg-size = 64 * 1024;
        max-size = 256 * 1024;
      };
    };
  };
}
