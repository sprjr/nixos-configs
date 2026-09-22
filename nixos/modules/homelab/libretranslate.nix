{ ... }:

{
  services.libretranslate = {
    enable = true;
    host = "0.0.0.0";
    port = 5000;
    extraArgs.load-only = "en,es,ja";
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5000 ];
}
