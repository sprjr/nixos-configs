{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.ollama = {
    package = pkgs.ollama-rocm;
    enable = true;
    host = "0.0.0.0";
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_GPU = "999";
      OLLAMA_NEW_ENGINE = "1";
      # Navi 10 (gfx1010) — verify with rocminfo on badgey
      HSA_OVERRIDE_GFX_VERSION = "10.1.0";
    };
  };

  networking.firewall.allowedTCPPorts = [ 11434 ];
}
