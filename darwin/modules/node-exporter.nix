{ pkgs, ... }:

{
  launchd.daemons.prometheus-node-exporter = {
    serviceConfig = {
      Label = "org.prometheus.node-exporter";
      ProgramArguments = [
        "${pkgs.prometheus-node-exporter}/bin/node_exporter"
        "--web.listen-address=:9100"
        "--collector.cpu"
        "--collector.filesystem"
        "--collector.loadavg"
        "--collector.meminfo"
        "--collector.netdev"
        "--collector.uname"
        "--collector.diskstats"
        "--no-collector.textfile"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/prometheus-node-exporter.log";
      StandardErrorPath = "/var/log/prometheus-node-exporter.log";
    };
  };
}
