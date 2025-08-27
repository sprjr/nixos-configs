{ config, pkgs, ... }:

let
 ipMonitor = pkgs.writeScript "ip-monitor.py" ''
  #!${pkgs.python3}/bin/python3
  import urllib.request
  import subprocess
  import os

  ipFile = "last_ip.txt"
  checkUrl = "https://ifconfig.me"
  ntfyTopic = "http://100.119.239.121:55455/rawliyosh-administration-notification-network-hso"

  def get_public_ip():
      with urllib.request.urlopen(checkUrl) as response:
          return response.read().decode("utf-8").strip()

  def run_on_change():
      current_ip = get_public_ip()

      # Load last IP (if exists)
      if os.path.exists(ipFile):
          with open(ipFile, "r") as f:
              last_ip = f.read().strip()
      else:
          last_ip = None

      if current_ip != last_ip:
          print(f"IP has changed from {last_ip} to {current_ip}")
          subprocess.run([
              "ntfy", "publish", ntfyTopic,
              f"Public IP has changed from {last_ip} to {current_ip}"
          ])
          with open(ipFile, "w") as f:
              f.write(current_ip)
      else:
          print(f"No change. Current IP is still {current_ip}. No action being taken.")

  if __name__ == "__main__":
      run_on_change()
  '';
in {
  systemd.services.ip-monitor = {
    description = "Monitor public IP address for changes and notify via ntfy";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${ipMonitor}";
      StateDirectory = "ip-monitor"; # /var/lib/ip-monitor
    };
  };

  systemd.timers.ip-monitor = {
    description = "Run ip-monitor every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      onUnitActiveSec = "1h";
    };
  };
}
