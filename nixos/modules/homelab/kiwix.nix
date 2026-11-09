{ config, lib, pkgs, ... }:

let
  cfg = config.homelab.kiwix;
  zimDir = "${cfg.dataDir}/zim";
  stagingDir = "${cfg.dataDir}/staging";
  currentDir = "${cfg.dataDir}/current";

  items = [
    { name = "wikipedia"; collection = "wikipedia"; prefix = "wikipedia_en_all_nopic_"; }
    { name = "wiktionary"; collection = "wiktionary"; prefix = "wiktionary_en_all_nopic_"; }
    { name = "wikivoyage"; collection = "wikivoyage"; prefix = "wikivoyage_en_all_maxi_"; }
    { name = "mdwiki"; collection = "other"; prefix = "mdwiki_en_all_maxi_"; }
    { name = "unix"; collection = "stack_exchange"; prefix = "unix.stackexchange.com_en_all_"; }
    { name = "askubuntu"; collection = "stack_exchange"; prefix = "askubuntu.com_en_all_"; }
    { name = "superuser"; collection = "stack_exchange"; prefix = "superuser.com_en_all_"; }
    { name = "security"; collection = "stack_exchange"; prefix = "security.stackexchange.com_en_all_"; }
  ];

  library = pkgs.linkFarm "kiwix-zims" (
    map (i: {
      name = "${i.name}.zim";
      path = "${currentDir}/${i.name}.zim";
    }) items
  );

  serveArgs = lib.escapeShellArgs (
    [ "--port" (toString cfg.port) "--skipInvalid" ] ++ map (i: "${library}/${i.name}.zim") items
  );

  itemTable = lib.concatMapStringsSep "\n" (i: "${i.name}|${i.collection}|${i.prefix}") items;

  updater = pkgs.writeShellApplication {
    name = "kiwix-update";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.systemd
      pkgs.zim-tools
    ];
    text = ''
      set -euo pipefail

      zim_dir=${zimDir}
      current=${currentDir}
      staging=${stagingDir}
      base="https://download.kiwix.org/zim"
      changed=0

      mkdir -p "$zim_dir" "$current" "$staging"

      while IFS='|' read -r name collection prefix; do
        [ -n "$name" ] || continue

        listing=$(curl -fsSL --retry 3 --retry-delay 10 --max-time 120 "$base/$collection/") || {
          echo "$name: listing unavailable for $collection" >&2
          continue
        }
        latest=$(printf '%s' "$listing" \
          | grep -oE "href=\"$prefix[0-9]{4}-[0-9]{2}\.zim\"" \
          | sed -e 's/^href="//' -e 's/"$//' \
          | sort | tail -n1) || true

        if [ -z "$latest" ]; then
          echo "$name: no release matching $prefix in $collection" >&2
          continue
        fi

        if [ "$(readlink "$current/$name.zim" 2>/dev/null || true)" = "../zim/$latest" ]; then
          echo "$name: up to date ($latest)"
          continue
        fi

        url="$base/$collection/$latest"
        size=$(curl -fsIL --retry 3 --max-time 60 "$url" \
          | awk 'tolower($1)=="content-length:" {n=$2} END {print n+0}')
        avail=$(df --output=avail -B1 "$zim_dir" | tail -n1)
        if [ "$avail" -lt $((size + 5368709120)) ]; then
          echo "$name: insufficient space for $latest" >&2
          continue
        fi

        echo "$name: fetching $latest ($size bytes)"
        curl -fL --retry 5 --retry-delay 30 -C - --max-time 86400 -o "$staging/$latest" "$url"
        zimcheck -A "$staging/$latest" >/dev/null

        mv -f "$staging/$latest" "$zim_dir/$latest"
        ln -sfn "../zim/$latest" "$current/$name.zim"
        find "$zim_dir" -maxdepth 1 -type f -name "$prefix*.zim" ! -name "$latest" -delete
        changed=1
      done <<ITEMS
      ${itemTable}
      ITEMS

      if [ "$changed" -eq 1 ]; then
        systemctl restart kiwix-serve.service
      fi
    '';
  };
in
{
  options.homelab.kiwix = {
    enable = lib.mkEnableOption "the local Kiwix offline library";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/unraid/Other/kiwix";
      description = "Directory holding the ZIM files, current-version symlinks and staging area.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8083;
      description = "Port for kiwix-serve.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "Sun *-*-* 04:30:00";
      description = "systemd OnCalendar expression for the ZIM update check.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.kiwix-dirs = {
      description = "Create Kiwix library directories";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      requiresMountsFor = [ cfg.dataDir ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = "mkdir -p ${zimDir} ${currentDir} ${stagingDir}";
    };

    systemd.services.kiwix-serve = {
      description = "ZIM file HTTP server";
      wantedBy = [ "multi-user.target" ];
      requiresMountsFor = [ cfg.dataDir ];
      after = [ "network.target" "kiwix-dirs.service" ];
      requires = [ "kiwix-dirs.service" ];
      unitConfig.ConditionPathExists = "${currentDir}/wikipedia.zim";
      serviceConfig = {
        Type = "exec";
        DynamicUser = true;
        ExecStart = "${pkgs.kiwix-tools}/bin/kiwix-serve ${serveArgs}";
        Restart = "on-failure";
        RestartSec = "10s";
        UMask = "0077";
        CapabilityBoundingSet = "";
        DeviceAllow = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_NETLINK" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
      };
    };

    systemd.services.kiwix-update = {
      description = "Fetch current Kiwix ZIM releases";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" "kiwix-dirs.service" ];
      requires = [ "kiwix-dirs.service" ];
      requiresMountsFor = [ cfg.dataDir ];
      serviceConfig = {
        Type = "oneshot";
        UMask = "0022";
        ExecStart = lib.getExe updater;
        TimeoutStartSec = "12h";
        Nice = 10;
        IOSchedulingClass = "idle";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
      };
    };

    systemd.timers.kiwix-update = {
      description = "Scheduled Kiwix ZIM update check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
