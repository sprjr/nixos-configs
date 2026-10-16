{ ... }:

{
  services.pumpkin = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 25565 ];
}
