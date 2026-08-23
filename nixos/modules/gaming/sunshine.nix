{ config, pkgs, ... }:

{
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    autoStart = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };
    settings = {
      port = 47989;

      capture = "kms";
      encoder = "nvenc";

      hevc_mode = 0;
      av1_mode = 0;

      nvenc_preset = 1;
      nvenc_twopass = "disabled";
      nvenc_spatial_aq = "disabled";
      nvenc_realtime_hags = true;
      nvenc_latency_over_power = true;

      lan_encryption_mode = 0;
      fec_percentage = 20;
      min_log_level = "info";
    };

    # mon-remote/mon-local (home/modules/user-space/hyprland/monitors.nix) toggle streaming mode.
    applications.apps = [
      {
        name = "Desktop";
        "prep-cmd" = [
          {
            do = "mon-remote";
            undo = "mon-local";
          }
        ];
      }
    ];
  };
}
