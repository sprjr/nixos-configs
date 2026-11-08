{ config, pkgs, lib, ... }:

let
  cfg = config.services.kev-watch;
  stateDir = "/var/lib/kev-watch";
  textfileDir = "/var/lib/prometheus-node-exporter/textfile";
  catalogFile = "${stateDir}/kev.json.new";
  prevFile = "${stateDir}/kev.prev.json";
  metricsFile = "${textfileDir}/kev.prom";

  script = pkgs.writeShellApplication {
    name = "kev-watch";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils pkgs.util-linux ];
    text = ''
      STATE=${stateDir}
      metrics=${metricsFile}
      ntfyUrlFile=${lib.escapeShellArg cfg.ntfyUrlFile}

      write_prom() {
        cat > "$1.tmp"
        chmod 0644 "$1.tmp"
        mv "$1.tmp" "$1"
      }

      write_run_metric() {
        now=$(date +%s)
        {
          printf 'kev_catalog_entries %s\n' "$2"
          printf 'kev_new_entries %s\n' "$3"
          printf 'kev_last_run_timestamp_seconds %s\n' "$now"
          printf 'kev_last_run_success %s\n' "$1"
        } | write_prom "$metrics"
      }

      if ! curl --fail --retry 3 --retry-delay 10 --max-time 90 -o "$STATE/kev.json.new" "${cfg.catalogUrl}"; then
        write_run_metric 0 0 0
        echo "failed to fetch KEV catalog" >&2
        exit 1
      fi

      if ! jq -e '.vulnerabilities | length > 0' "$STATE/kev.json.new" >/dev/null 2>&1; then
        write_run_metric 0 0 0
        echo "KEV catalog failed validation" >&2
        exit 1
      fi

      if [ ! -f "$STATE/kev.prev.json" ]; then
        mv "$STATE/kev.json.new" "$STATE/kev.prev.json"
        total=$(jq -r '.vulnerabilities | length' "$STATE/kev.prev.json")
        write_run_metric 1 "$total" 0
        exit 0
      fi

      current=$(jq -r '[.vulnerabilities[].cveID] | sort | .[]' "$STATE/kev.json.new")
      previous=$(jq -r '[.vulnerabilities[].cveID] | sort | .[]' "$STATE/kev.prev.json")
      new_ids=$(comm -23 <(printf '%s\n' "$current" | sort) <(printf '%s\n' "$previous" | sort))
      new_count=$(printf '%s\n' "$new_ids" | grep -c '^CVE-' || true)

      # Atomically replace the snapshot only after a successful fetch and diff.
      mv "$STATE/kev.json.new" "$STATE/kev.prev.json"
      total=$(jq -r '.vulnerabilities | length' "$STATE/kev.prev.json")
      write_run_metric 1 "$total" "$new_count"

      if [ "$new_count" -gt 0 ]; then
        ntfyUrl=$(cat "$ntfyUrlFile")
        title="CISA KEV: $new_count new exploited vulnerabilit"
        if [ "$new_count" -eq 1 ]; then
          title="''${title}y"
        else
          title="''${title}ies"
        fi

        body=$(
          printf '%s\n' "$new_ids" | head -20 | while read -r cve; do
            jq -r --arg cve "$cve" '.vulnerabilities[] | select(.cveID == $cve) | "\(.cveID)  \(.vendorProject)  \(.product)  (added \(.dateAdded))"' "$STATE/kev.prev.json"
          done
        )
        extra=$((new_count - 20))
        if [ "$extra" -gt 0 ]; then
          body=$(printf '%s\nand %s more\n' "$body" "$extra")
        fi

        {
          printf 'Title: %s\n' "$title"
          printf 'Priority: 4\n'
          printf 'Tags: rotating_light\n'
          printf '\n%s\n' "$body"
        } | curl --fail --max-time 30 -H "Content-Type: text/plain" -d @- "$ntfyUrl" >/dev/null 2>&1 || echo "ntfy notification failed" >&2
      fi
    '';
  };
in
{
  options.services.kev-watch = {
    enable = lib.mkEnableOption "daily CISA KEV catalog diff watcher for the personal homelab";

    ntfyUrlFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the ntfy topic URL pushed when new KEV entries are detected.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 06:00:00";
      description = "systemd OnCalendar expression for the daily KEV snapshot poll.";
    };

    catalogUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json";
      description = "CISA Known Exploited Vulnerabilities JSON catalog URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.kev-watch = {
      isSystemUser = true;
      group = "kev-watch";
      home = stateDir;
    };
    users.groups.kev-watch = { };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0750 kev-watch kev-watch -"
      "a+ ${textfileDir} - - - - u:kev-watch:rwx"
    ];

    systemd.services.kev-watch = {
      description = "Watch CISA KEV catalog for newly exploited vulnerabilities";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment.HOME = stateDir;
      serviceConfig = {
        Type = "oneshot";
        User = "kev-watch";
        Group = "kev-watch";
        StateDirectory = "kev-watch";
        StateDirectoryMode = "0750";
        UMask = "0027";
        ExecStart = lib.getExe script;
        TimeoutStartSec = "15min";
        Nice = 10;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ textfileDir ];
      };
    };

    systemd.timers.kev-watch = {
      description = "Scheduled CISA KEV catalog poll";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
