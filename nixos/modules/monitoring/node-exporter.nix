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

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 ];
}
