{ config, pkgs, ... }:

{
  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
    };
  };

  # Scraped by the Prometheus server on shikisha over the tailnet.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 ];
}
