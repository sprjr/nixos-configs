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
      value = { owner = "syncthing"; };
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
      after = [ "syncthing-setup.service" "syncthing.service" "syncthing-init.service" ];
      requires = [ "syncthing.service" "syncthing-init.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "syncthing";
        Restart = "on-failure";
        RestartSec = "30s";
      };
      path = with pkgs; [ curl libxml2 jq ];
      script = ''
        for i in $(seq 1 60); do
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

        # Build DEVICE_IDS from IDs that are actually registered in Syncthing.
        # This guards against invalid IDs in secrets (wrong length, empty, etc.)
        # that would cause Syncthing to reject the entire folder PUT with 400.
        REGISTERED=$(curl -sf -H "X-API-Key: $APIKEY" http://127.0.0.1:8384/rest/config/devices)

        TARGET_IDS='[]'
        ${lib.concatMapStrings (name: ''
          _id=$(cat ${lib.escapeShellArg config.sops.secrets."syncthing/device-id/${name}".path} 2>/dev/null || true)
          [ -n "$_id" ] && TARGET_IDS=$(printf '%s' "$TARGET_IDS" | jq --arg id "$_id" '. + [$id]')
        '') cfg.clientDevices}

        DEVICE_IDS=$(printf '%s' "$REGISTERED" | \
          jq --argjson targets "$TARGET_IDS" \
          '[.[] | select(.deviceID as $id | $targets | index($id) != null) | {deviceID: .deviceID}]')

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

    systemd.services.syncthing-setup = {
      description = "Ensure Syncthing config directory ownership";
      before = [ "syncthing.service" ];
      wantedBy = [ "syncthing.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/install -d -m 0700 -o syncthing -g syncthing /var/lib/syncthing/.config/syncthing";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/syncthing/.config/syncthing 0700 syncthing syncthing -"
      "d ${cfg.vaultPath} 0700 syncthing syncthing -"
    ];
  };
}
