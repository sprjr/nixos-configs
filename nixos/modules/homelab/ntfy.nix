{ config, ... }:

let
  port = 55455;
in
{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://${config.networking.hostName}:${toString port}";
      listen-http = ":${toString port}";
    };
  };

  # Tailnet only; publishers use plain HTTP on this port.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
}
