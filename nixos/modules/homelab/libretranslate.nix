{ ... }:

{
  services.libretranslate = {
    enable = true;
    host = "0.0.0.0";
    port = 5000;
    extraArgs.load-only = "en,es,ja";
  };

  # Force float32; ctranslate2's auto picks an int8 path that corrupts the es_en model.
  systemd.services.libretranslate.environment.ARGOS_COMPUTE_TYPE = "float32";

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5000 ];
}
