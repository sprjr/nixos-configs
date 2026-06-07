{ config, ... }:

{
  sops.secrets."atticd/env-file" = {
    owner = "atticd";
    restartUnits = [ "atticd.service" ];
  };
  sops.secrets."atticd/signing-key" = {
    owner = "atticd";
    restartUnits = [ "atticd.service" ];
  };

  # Allow all Tailscale peers to reach the cache without a port-level rule.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets."atticd/env-file".path;
    settings = {
      listen = "[::]:8089";
      jwt = { };
      signing-key-path = config.sops.secrets."atticd/signing-key".path;
      # Warning: changing chunking values breaks deduplication for existing NARs.
      chunking = {
        nar-size-threshold = 64 * 1024;
        min-size = 16 * 1024;
        avg-size = 64 * 1024;
        max-size = 256 * 1024;
      };
    };
  };
}
