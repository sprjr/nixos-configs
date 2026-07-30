{ config, pkgs, ... }:

let
  textfileDir = "/var/lib/prometheus-node-exporter/textfile";
in
{
  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" "textfile" ];
        port = 9100;
        extraFlags = [
          "--collector.textfile.directory=${textfileDir}"
        ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${textfileDir} 0755 root root -"
  ];

  # Scraped by the Prometheus server on shikisha over the tailnet.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 ];
}
