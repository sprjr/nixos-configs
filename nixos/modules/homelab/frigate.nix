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

  # go2rtc runs as its own unit and expands ${VAR} env refs from the template below.
  sops.templates."go2rtc-env" = {
    mode = "0400";
    content = ''
      FRIGATE_FRONT_DOOR_RTSP=${config.sops.placeholder."frigate/front-door-rtsp"}
      FRIGATE_GARAGE_RTSP=${config.sops.placeholder."frigate/garage-rtsp"}
    '';
  };

  services.go2rtc = {
    enable = true;
    settings.streams = {
      front_door = "$${FRIGATE_FRONT_DOOR_RTSP}";
      garage = "$${FRIGATE_GARAGE_RTSP}";
    };
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

  # Dynamic-user unit; the manager reads the EnvironmentFile as root, so the
  # template needs no owner. Must start after the secrets are mounted.
  systemd.services.go2rtc = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    serviceConfig = {
      EnvironmentFile = [ config.sops.templates."go2rtc-env".path ];
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
