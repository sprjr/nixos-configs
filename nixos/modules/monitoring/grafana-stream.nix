{
  config,
  pkgs,
  lib,
  ...
}:

let
  hlsDir = "/var/lib/grafana-stream/hls";
  display = ":99";
  resolution = "1920x1080";
  grafanaAddr = "127.0.0.1:3000";
  proxyPort = 3080;
  hlsPort = 8080;
  playlistName = "Homelab";

  streamDeps = with pkgs; [
    xorg-server
    chromium
    ffmpeg
    curl
    jq
    coreutils
  ];

  provisionPlaylists = pkgs.writeShellScript "grafana-provision-playlists" ''
    set -euo pipefail
    TOKEN=$(cat ${config.sops.secrets."grafana/service-account-token".path})
    GRAFANA="http://${grafanaAddr}"
    AUTH="Authorization: Bearer $TOKEN"

    until curl -sf -H "$AUTH" "$GRAFANA/api/health" > /dev/null 2>&1; do
      sleep 2
    done

    provision_playlist() {
      local name="$1" tag="$2"
      local existing
      existing=$(curl -sf -H "$AUTH" "$GRAFANA/api/playlists" \
        | jq -r ".[] | select(.name == \"$name\") | .uid")

      local payload
      payload=$(jq -n --arg n "$name" --arg t "$tag" '{
        name: $n,
        interval: "30s",
        items: [{type: "dashboard_by_tag", value: $t}]
      }')

      if [ -n "$existing" ]; then
        curl -sf -X PUT -H "$AUTH" -H "Content-Type: application/json" \
          -d "$payload" "$GRAFANA/api/playlists/$existing" > /dev/null
      else
        curl -sf -X POST -H "$AUTH" -H "Content-Type: application/json" \
          -d "$payload" "$GRAFANA/api/playlists" > /dev/null
      fi
    }

    provision_playlist "Homelab" "homelab"
    provision_playlist "Nix" "nixos"
  '';

  streamCapture = pkgs.writeShellScript "grafana-stream-capture" ''
    set -euo pipefail
    TOKEN=$(cat ${config.sops.secrets."grafana/service-account-token".path})
    GRAFANA="http://${grafanaAddr}"
    PROXY="http://127.0.0.1:${toString proxyPort}"

    PLAYLIST_UID=$(curl -sf -H "Authorization: Bearer $TOKEN" "$GRAFANA/api/playlists" \
      | jq -r '.[] | select(.name == "${playlistName}") | .uid')

    if [ -z "$PLAYLIST_UID" ]; then
      echo "Playlist '${playlistName}' not found" >&2
      exit 1
    fi

    mkdir -p ${hlsDir}

    Xvfb ${display} -screen 0 ${resolution}x24 &
    sleep 2

    export DISPLAY=${display}
    chromium \
      --no-sandbox \
      --disable-gpu \
      --disable-software-rasterizer \
      --kiosk \
      --window-size=${builtins.replaceStrings [ "x" ] [ "," ] resolution} \
      --user-data-dir=/tmp/grafana-kiosk \
      --no-first-run \
      --disable-translate \
      --disable-extensions \
      --disable-default-apps \
      --disable-sync \
      "$PROXY/playlists/play/$PLAYLIST_UID?kiosk" &
    sleep 10

    exec ffmpeg -nostdin \
      -f x11grab -framerate 5 -video_size ${resolution} -i ${display} \
      -c:v libx264 -preset ultrafast -tune zerolatency \
      -f hls -hls_time 2 -hls_list_size 5 -hls_flags delete_segments \
      ${hlsDir}/dashboard.m3u8
  '';
in

{
  sops.secrets."grafana/service-account-token" = {
    owner = config.services.nginx.user;
    mode = "0400";
    restartUnits = [
      "nginx.service"
      "grafana-stream.service"
    ];
  };

  sops.templates."nginx-grafana-stream-auth" = {
    owner = config.services.nginx.user;
    mode = "0400";
    content = ''
      proxy_set_header Authorization "Bearer ${config.sops.placeholder."grafana/service-account-token"}";
    '';
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts."grafana-auth-proxy" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = proxyPort;
        }
      ];
      locations."/" = {
        proxyPass = "http://${grafanaAddr}";
        proxyWebsockets = true;
        extraConfig = ''
          include ${config.sops.templates."nginx-grafana-stream-auth".path};
        '';
      };
    };

    virtualHosts."grafana-hls" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = hlsPort;
        }
      ];
      locations."/stream/" = {
        alias = "${hlsDir}/";
        extraConfig = ''
          types {
            application/vnd.apple.mpegurl m3u8;
            video/mp2t ts;
          }
          add_header Cache-Control "no-cache, no-store";
          add_header Access-Control-Allow-Origin "*";
        '';
      };
    };
  };

  systemd.services.grafana-playlists = {
    description = "Provision Grafana playlists";
    after = [ "grafana.service" ];
    requires = [ "grafana.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = provisionPlaylists;
      path = with pkgs; [
        curl
        jq
      ];
    };
  };

  systemd.services.grafana-stream = {
    description = "Grafana dashboard HLS stream";
    after = [
      "grafana.service"
      "grafana-playlists.service"
      "nginx.service"
    ];
    requires = [
      "grafana.service"
      "nginx.service"
    ];
    wants = [ "grafana-playlists.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = streamCapture;
      KillMode = "control-group";
      Restart = "on-failure";
      RestartSec = 10;
      StateDirectory = "grafana-stream";
      path = streamDeps;
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ hlsPort ];
}
