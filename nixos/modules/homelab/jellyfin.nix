{ pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    # dataDir/configDir/cacheDir stay on local disk (default /var/lib/jellyfin).
    # /mnt/unraid/Media is added as a library folder in the web UI, not as dataDir —
    # SQLite over NFS corrupts.
    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
  };

  # VAAPI driver for Intel HD Graphics 630 (Kaby Lake / Gen9.5) transcoding.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };
}
