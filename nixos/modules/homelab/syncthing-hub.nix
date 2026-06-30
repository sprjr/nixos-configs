{ config, lib, pkgs, ... }:

let
  cfg = config.services.syncthing-hub;
in {
  options.services.syncthing-hub = {
    enable = lib.mkEnableOption "Syncthing hub controller";

    clientDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Names of client devices. Each must have a sops secret at syncthing/device-id/<name>.";
    };

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/syncthing/Documents/Obsidian/Vaults";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.listToAttrs (map (name: {
      name = "syncthing/device-id/${name}";
      value = {};
    }) cfg.clientDevices) // {
      "syncthing/hub/cert" = {
        owner = "syncthing";
        path = "/var/lib/syncthing/.config/syncthing/cert.pem";
      };
      "syncthing/hub/key" = {
        owner = "syncthing";
        path = "/var/lib/syncthing/.config/syncthing/key.pem";
      };
    };

    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 21027 ];

    services.syncthing = {
      enable = true;
      user = "syncthing";
      group = "syncthing";
      dataDir = "/var/lib/syncthing";
      configDir = "/var/lib/syncthing/.config/syncthing";
      overrideDevices = false;
      overrideFolders = false;

      settings = {
        gui = {
          address = "127.0.0.1:8384";
          insecureSkipHostcheck = false;
        };

        options = {
          urAccepted = -1;
          relaysEnabled = true;
          localAnnounceEnabled = true;
          globalAnnounceEnabled = true;
        };
      };
    };

    systemd.services.syncthing-configure = {
      description = "Configure Syncthing devices and folders";
      after = [ "syncthing.service" ];
      wants = [ "syncthing.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "syncthing";
      };
      path = with pkgs; [ curl libxml2 jq ];
      script = ''
        for i in $(seq 1 30); do
          curl -sf http://127.0.0.1:8384/rest/system/ping > /dev/null && break
          sleep 2
        done

        APIKEY=$(xmllint --xpath "string(//configuration/gui/apikey)" \
          ${config.services.syncthing.configDir}/config.xml)

        add_device() {
          local name="$1"
          local id_file="$2"
          local device_id
          device_id=$(cat "$id_file")

          local exists
          exists=$(curl -sf -H "X-API-Key: $APIKEY" http://127.0.0.1:8384/rest/config/devices | \
            jq -r --arg id "$device_id" '.[] | select(.deviceID == $id) | .deviceID')

          if [ -z "$exists" ]; then
            curl -sf -X POST \
              -H "X-API-Key: $APIKEY" \
              -H "Content-Type: application/json" \
              http://127.0.0.1:8384/rest/config/devices \
              --data "{\"deviceID\": \"$device_id\", \"name\": \"$name\", \"autoAcceptFolders\": false}" \
              > /dev/null
          fi
        }

        ${lib.concatMapStrings (name: ''
          add_device ${lib.escapeShellArg name} ${lib.escapeShellArg config.sops.secrets."syncthing/device-id/${name}".path}
        '') cfg.clientDevices}

        DEVICE_IDS=$(
          {
            ${lib.concatMapStrings (name: ''
              echo "{\"deviceID\": \"$(cat ${lib.escapeShellArg config.sops.secrets."syncthing/device-id/${name}".path})\"}"
            '') cfg.clientDevices}
          } | jq -s '.'
        )

        existing=$(curl -sf -H "X-API-Key: $APIKEY" \
          http://127.0.0.1:8384/rest/config/folders/obsidian-vaults 2>/dev/null || echo "")

        if [ -z "$existing" ]; then
          curl -sf -X POST \
            -H "X-API-Key: $APIKEY" \
            -H "Content-Type: application/json" \
            http://127.0.0.1:8384/rest/config/folders \
            --data "{
              \"id\": \"obsidian-vaults\",
              \"label\": \"Obsidian Vaults\",
              \"path\": \"${cfg.vaultPath}\",
              \"devices\": $DEVICE_IDS,
              \"versioning\": {
                \"type\": \"staggered\",
                \"params\": {\"cleanInterval\": \"3600\", \"maxAge\": \"7776000\"}
              },
              \"ignorePerms\": true
            }" > /dev/null
        else
          curl -sf -X PUT \
            -H "X-API-Key: $APIKEY" \
            -H "Content-Type: application/json" \
            http://127.0.0.1:8384/rest/config/folders/obsidian-vaults \
            --data "$(echo "$existing" | jq --argjson devs "$DEVICE_IDS" '.devices = $devs')" \
            > /dev/null
        fi
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/syncthing/.config/syncthing 0700 syncthing syncthing -"
      "d ${cfg.vaultPath} 0700 syncthing syncthing -"
    ];
  };
}
