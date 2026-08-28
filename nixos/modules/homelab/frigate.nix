{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops.secrets."frigate/mqtt-password" = { };
  sops.secrets."frigate/front-door-rtsp" = { };
  sops.secrets."frigate/garage-rtsp" = { };

  sops.templates."frigate-env" = {
    owner = "frigate";
    mode = "0400";
    content = ''
      FRIGATE_MQTT_PASSWORD=${config.sops.placeholder."frigate/mqtt-password"}
      FRIGATE_FRONT_DOOR_RTSP=${config.sops.placeholder."frigate/front-door-rtsp"}
      FRIGATE_GARAGE_RTSP=${config.sops.placeholder."frigate/garage-rtsp"}
    '';
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

      go2rtc.streams = {
        front_door = "{FRIGATE_FRONT_DOOR_RTSP}";
        garage = "{FRIGATE_GARAGE_RTSP}";
      };

      cameras = {
        front_door = {
          enabled = true;
          ffmpeg.inputs = [{
            path = "rtsp://127.0.0.1:8554/front_door";
            roles = [ "detect" ];
          }];
          detect = {
            enabled = true;
            width = 1280;
            height = 720;
          };
          record.enabled = false;
        };
        garage = {
          enabled = true;
          ffmpeg.inputs = [{
            path = "rtsp://127.0.0.1:8554/garage";
            roles = [ "detect" ];
          }];
          detect = {
            enabled = true;
            width = 1280;
            height = 720;
          };
          record.enabled = false;
        };
      };
    };
  };

  users.users.frigate.extraGroups = [ "video" ];

  systemd.services.frigate = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    serviceConfig = {
      EnvironmentFile = [ config.sops.templates."frigate-env".path ];
    };
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
