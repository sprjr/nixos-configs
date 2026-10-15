{ config, lib, pkgs, ... }:

let
  cfg = config.services.syncthing-hub;
  allDevices = lib.unique (cfg.clientDevices ++ cfg.claudeDevices);
  idFile = name: config.sops.secrets."syncthing/device-id/${name}".path;
  idFiles = names: lib.concatMapStringsSep " " (name: lib.escapeShellArg (idFile name)) names;
  claudeStignore = pkgs.writeText "claude-config.stignore" (import ./claude-stignore.nix);
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

    sharedPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/syncthing/shared";
      description = "Hub path for the general-purpose shared folder, offered to all clientDevices.";
    };

    claudeDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Devices sharing the claude-config folder (~/.claude). Each must have a sops secret at syncthing/device-id/<name>.";
    };

    claudePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/syncthing/claude-config";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.listToAttrs (map (name: {
      name = "syncthing/device-id/${name}";
      value = { owner = "syncthing"; };
    }) allDevices) // {
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
          add_device ${lib.escapeShellArg name} ${lib.escapeShellArg (idFile name)}
        '') allDevices}

        # Build device lists from IDs that are actually registered in Syncthing.
        # This guards against invalid IDs in secrets (wrong length, empty, etc.)
        # that would cause Syncthing to reject the entire folder PUT with 400.
        REGISTERED=$(curl -sf -H "X-API-Key: $APIKEY" http://127.0.0.1:8384/rest/config/devices)

        # Usage: device_ids_for <id-file>...
        device_ids_for() {
          local targets='[]' _id f
          for f in "$@"; do
            _id=$(cat "$f" 2>/dev/null || true)
            [ -n "$_id" ] && targets=$(printf '%s' "$targets" | jq --arg id "$_id" '. + [$id]')
          done
          printf '%s' "$REGISTERED" | \
            jq --argjson targets "$targets" \
            '[.[] | select(.deviceID as $id | $targets | index($id) != null) | {deviceID: .deviceID}]'
        }

        # Create the folder with staggered versioning, or reset its device list if it exists
        # Usage: ensure_folder <id> <label> <path> <ignorePerms> <devices-json>
        ensure_folder() {
          local id="$1" label="$2" path="$3" ignore_perms="$4" devices="$5"
          local existing
          existing=$(curl -sf -H "X-API-Key: $APIKEY" \
            "http://127.0.0.1:8384/rest/config/folders/$id" 2>/dev/null || echo "")

          if [ -z "$existing" ]; then
            curl -sf -X POST \
              -H "X-API-Key: $APIKEY" \
              -H "Content-Type: application/json" \
              http://127.0.0.1:8384/rest/config/folders \
              --data "$(jq -n \
                --arg id "$id" --arg label "$label" --arg path "$path" \
                --argjson ignorePerms "$ignore_perms" --argjson devs "$devices" \
                '{
                  id: $id,
                  label: $label,
                  path: $path,
                  devices: $devs,
                  versioning: {
                    type: "staggered",
                    params: {cleanInterval: "3600", maxAge: "7776000"}
                  },
                  ignorePerms: $ignorePerms
                }')" > /dev/null
          else
            curl -sf -X PUT \
              -H "X-API-Key: $APIKEY" \
              -H "Content-Type: application/json" \
              "http://127.0.0.1:8384/rest/config/folders/$id" \
              --data "$(echo "$existing" | jq --argjson devs "$devices" '.devices = $devs')" \
              > /dev/null
          fi
        }

        ensure_folder obsidian-vaults "Obsidian Vaults" ${lib.escapeShellArg cfg.vaultPath} true \
          "$(device_ids_for ${idFiles cfg.clientDevices})"

        ensure_folder shared "Shared" ${lib.escapeShellArg cfg.sharedPath} true \
          "$(device_ids_for ${idFiles cfg.clientDevices})"
      '' + lib.optionalString (cfg.claudeDevices != []) ''

        # Ignore patterns must be in place before the folder exists, or the first scan
        # would pick up credentials and transcripts relayed from a misconfigured client.
        install -m 0644 ${claudeStignore} ${lib.escapeShellArg cfg.claudePath}/.stignore

        ensure_folder claude-config "Claude Config" ${lib.escapeShellArg cfg.claudePath} false \
          "$(device_ids_for ${idFiles cfg.claudeDevices})"
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
      "d ${cfg.sharedPath} 0700 syncthing syncthing -"
    ] ++ lib.optional (cfg.claudeDevices != []) "d ${cfg.claudePath} 0700 syncthing syncthing -";
  };
}
