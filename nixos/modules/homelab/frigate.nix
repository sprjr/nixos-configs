{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops.secrets."frigate/env-file" = {
    owner = "frigate";
    mode = "0400";
  };

  services.frigate = {
    enable = true;
    hostname = "badgey";
    vaapiDriver = "radeonsi";
    checkConfig = false;

    settings = {
      mqtt = {
        enabled = true;
        host = "shikisha";
        port = 1883;
        user = "frigate";
        password = "{FRIGATE_MQTT_PASSWORD}";
      };

      ffmpeg = {
        hwaccel_args = "preset-vaapi";
      };

      detectors = {
        cpu = {
          type = "cpu";
          num_threads = 4;
        };
      };

      cameras = { };
    };
  };

  users.users.frigate.extraGroups = [ "video" ];

  systemd.services.frigate.serviceConfig = {
    EnvironmentFile = config.sops.secrets."frigate/env-file".path;
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      8554
      8555
    ];
    allowedUDPPorts = [ 8555 ];
  };
}
