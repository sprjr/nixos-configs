{ config, pkgs, ... }:

let
  textfileDir = "/var/lib/prometheus-node-exporter/textfile";
in
{
  users.groups.promtext = { };

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
    "d ${textfileDir} 0775 root promtext -"
  ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 ];
  networking.firewall.interfaces.netbird0.allowedTCPPorts = [ 9100 ];
}
