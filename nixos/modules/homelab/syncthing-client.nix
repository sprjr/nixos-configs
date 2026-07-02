{ config, lib, pkgs, ... }:

let
  cfg = config.services.syncthing-client;
in {
  options.services.syncthing-client = {
    enable = lib.mkEnableOption "Syncthing client";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      description = "Local path for the Obsidian Vaults folder.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."syncthing/hub/device-id" = { owner = "patrick"; };

    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 21027 ];

    services.syncthing = {
      enable = true;
      user = "patrick";
      group = "users";
      dataDir = "/home/patrick";
      overrideDevices = false;
      overrideFolders = false;
    };

    systemd.services.syncthing-configure = {
      description = "Configure Syncthing hub device and obsidian-vaults folder";
      after = [ "syncthing.service" ];
      requires = [ "syncthing.service" ];
      wants = [ "syncthing.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "patrick";
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

        HUB_ID=$(cat ${config.sops.secrets."syncthing/hub/device-id".path})

        exists=$(curl -sf -H "X-API-Key: $APIKEY" http://127.0.0.1:8384/rest/config/devices | \
          jq -r --arg id "$HUB_ID" '.[] | select(.deviceID == $id) | .deviceID')

        if [ -z "$exists" ]; then
          curl -sf -X POST \
            -H "X-API-Key: $APIKEY" \
            -H "Content-Type: application/json" \
            http://127.0.0.1:8384/rest/config/devices \
            --data "{\"deviceID\": \"$HUB_ID\", \"name\": \"shikisha\", \"autoAcceptFolders\": false}" \
            > /dev/null
        fi

        existing_folder=$(curl -sf -H "X-API-Key: $APIKEY" \
          http://127.0.0.1:8384/rest/config/folders/obsidian-vaults 2>/dev/null || echo "")

        if [ -z "$existing_folder" ]; then
          curl -sf -X POST \
            -H "X-API-Key: $APIKEY" \
            -H "Content-Type: application/json" \
            http://127.0.0.1:8384/rest/config/folders \
            --data "{
              \"id\": \"obsidian-vaults\",
              \"label\": \"Obsidian Vaults\",
              \"path\": \"${cfg.vaultPath}\",
              \"devices\": [{\"deviceID\": \"$HUB_ID\"}],
              \"ignorePerms\": true
            }" > /dev/null
        else
          hub_in_folder=$(echo "$existing_folder" | \
            jq -r --arg id "$HUB_ID" '.devices[]? | select(.deviceID == $id) | .deviceID')

          if [ -z "$hub_in_folder" ]; then
            curl -sf -X PUT \
              -H "X-API-Key: $APIKEY" \
              -H "Content-Type: application/json" \
              http://127.0.0.1:8384/rest/config/folders/obsidian-vaults \
              --data "$(echo "$existing_folder" | jq --arg id "$HUB_ID" \
                '.devices += [{"deviceID": $id}]')" \
              > /dev/null
          fi
        fi
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.vaultPath} 0755 patrick users -"
    ];
  };
}
