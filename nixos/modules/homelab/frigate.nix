{
  config,
  pkgs,
  lib,
  ...
}:

let
  g4Cameras = [
    "g4-0"
  ];

  streamName = name: lib.replaceStrings [ "-" ] [ "_" ] name;
  envName = name: "FRIGATE_${lib.toUpper (streamName name)}_RTSP";
in
{
  sops.secrets = {
    "frigate/mqtt-password" = { };
    "frigate/front-door-rtsp" = { };
    "frigate/garage-rtsp" = { };
  } // lib.genAttrs (map (name: "frigate/${name}") g4Cameras) (_: { });

  sops.templates."frigate-env" = {
    owner = "frigate";
    mode = "0400";
    content = ''
      FRIGATE_MQTT_PASSWORD=${config.sops.placeholder."frigate/mqtt-password"}
      FRIGATE_FRONT_DOOR_RTSP=${config.sops.placeholder."frigate/front-door-rtsp"}
      FRIGATE_GARAGE_RTSP=${config.sops.placeholder."frigate/garage-rtsp"}
    '' + lib.concatMapStrings (name: ''
      ${envName name}=${config.sops.placeholder."frigate/${name}"}
    '') g4Cameras;
  };

  # go2rtc runs as its own unit and expands ${VAR} env refs from the template below.
  sops.templates."go2rtc-env" = {
    mode = "0400";
    content = ''
      FRIGATE_FRONT_DOOR_RTSP=${config.sops.placeholder."frigate/front-door-rtsp"}
      FRIGATE_GARAGE_RTSP=${config.sops.placeholder."frigate/garage-rtsp"}
    '' + lib.concatMapStrings (name: ''
      ${envName name}=${config.sops.placeholder."frigate/${name}"}
    '') g4Cameras;
  };

  services.go2rtc = {
    enable = true;
    settings.streams = {
      front_door = "\${FRIGATE_FRONT_DOOR_RTSP}";
      garage = "\${FRIGATE_GARAGE_RTSP}";
    } // lib.genAttrs (map streamName g4Cameras) (name: "\${" + envName name + "}");
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

      objects.track = [
        "person"
        "car"
      ];

      # frigate-analyzer fetches /api/events/<id>/snapshot.jpg, which needs snapshots
      snapshots = {
        enabled = true;
        bounding_box = true;
        retain.default = 7;
      };

      # Plate reads land on car events as recognized_license_plate (Frigate >= 0.16)
      lpr.enabled = true;

      cameras = {
        front_door = {
          enabled = true;
          ffmpeg.inputs = [{
            path = "rtsp://127.0.0.1:8554/front_door";
            roles = [ "detect" "record" ];
          }];
          detect = {
            enabled = true;
            width = 1280;
            height = 720;
          };
          # Review items (frigate/reviews) are only generated with recording enabled
          record.enabled = true;
          # Placeholder polygons (relative x,y pairs); replace with output from the Frigate UI zone editor
          zones = {
            porch.coordinates = "0.35,0.55,0.65,0.55,0.65,1,0.35,1";
            walkway.coordinates = "0.25,0.35,0.75,0.35,0.65,0.55,0.35,0.55";
            driveway.coordinates = "0,0.2,0.25,0.2,0.25,1,0,1";
          };
          review.alerts.required_zones = [
            "porch"
            "walkway"
          ];
        };
        garage = {
          enabled = true;
          ffmpeg.inputs = [{
            path = "rtsp://127.0.0.1:8554/garage";
            roles = [ "detect" "record" ];
          }];
          detect = {
            enabled = true;
            width = 1280;
            height = 720;
          };
          record.enabled = true;
        };
      } // lib.genAttrs (map streamName g4Cameras) (name: {
        enabled = true;
        ffmpeg.inputs = [{
          path = "rtsp://127.0.0.1:8554/${streamName name}";
          roles = [ "detect" "record" ];
        }];
        detect = {
          enabled = true;
          width = 1280;
          height = 720;
        };
        record.enabled = true;
      });
    };
  };

  users.users.frigate.extraGroups = [ "video" ];

  systemd.services.frigate = {
    after = [ "sops-secrets-rendered.service" ];
    requires = [ "sops-secrets-rendered.service" ];
    serviceConfig = {
      EnvironmentFile = [ config.sops.templates."frigate-env".path ];
    };
  };

  # Dynamic-user unit; the manager reads the EnvironmentFile as root, so the
  # template needs no owner. Must start after the secrets are mounted.
  systemd.services.go2rtc = {
    after = [ "sops-secrets-rendered.service" ];
    requires = [ "sops-secrets-rendered.service" ];
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
