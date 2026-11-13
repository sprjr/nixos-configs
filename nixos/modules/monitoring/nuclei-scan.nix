{ config, pkgs, lib, ... }:

let
  cfg = config.services.nuclei-scan;
  stateDir = "/var/lib/nuclei-scan";
  resultsDir = "${stateDir}/results";
  textfileDir = "/var/lib/prometheus-node-exporter/textfile";

  # Tags each finding with the configured target name; JSON "host" is absent for ssl/network templates.
  annotate = pkgs.writeText "nuclei-annotate.jq" ''
    (.["template-id"] + " " + (.["matched-at"] // "")) as $key
    | . + {
      "scan-target": $target,
      "accepted": any($accepted[]; . == $key)
    }
  '';

  # One gauge per open, non-accepted finding; the file is replaced each time the target is scanned.
  findingMetrics = pkgs.writeText "nuclei-metrics.jq" ''
    def esc: gsub("\\\\"; "\\\\") | gsub("\""; "\\\"") | gsub("\n"; "\\n");
    select(.accepted | not)
    | "nuclei_finding{target=\"\(.["scan-target"] | esc)\",template_id=\"\(.["template-id"] | esc)\",finding_severity=\"\(.info.severity | esc)\",name=\"\(.info.name | esc)\",matched_at=\"\(.["matched-at"] | esc)\"} 1"
  '';

  excludeArgs = lib.optionalString (cfg.excludeTemplateIds != [ ]) "-eid ${lib.concatStringsSep "," cfg.excludeTemplateIds}";

  # naabu finds open ports; nuclei scans each host:port. Results land atomically for Alloy.
  scan = pkgs.writeShellApplication {
    name = "nuclei-scan";
    runtimeInputs = [ pkgs.naabu pkgs.nuclei pkgs.coreutils pkgs.jq pkgs.util-linux ];
    text = ''
      mode=$1
      today=$(date +%F)
      mkdir -p "${stateDir}/ports" "${stateDir}/daily"

      # Atomic replace so node-exporter never reads a partial file
      write_prom() {
        cat > "$1.tmp"
        chmod 0644 "$1.tmp"
        mv "$1.tmp" "$1"
      }

      write_run_metric() {
        printf 'nuclei_scan_last_run_timestamp_seconds{mode="%s"} %s\nnuclei_scan_last_run_success{mode="%s"} %s\n' \
          "$mode" "$(date +%s)" "$mode" "$1" | write_prom "${textfileDir}/nuclei-run-$mode.prom"
      }

      # Once per day at most; refresh failure falls back to the existing set
      update_templates() {
        local stamp="${stateDir}/templates-updated"
        if [ "$(cat "$stamp" 2>/dev/null)" = "$today" ]; then
          return 0
        fi
        if nuclei -ut -ud "${stateDir}/nuclei-templates" -silent >/dev/null 2>&1; then
          echo "$today" > "$stamp"
        else
          echo "template update failed; using existing set" >&2
        fi
      }

      # Returns 0 when scanned, 1 when no ports are open (host down), 2 on failure
      scan_target() {
        local target=$1 ports raw out run port_count findings
        ports="${stateDir}/ports/$target.txt"
        raw="${stateDir}/$target.raw.jsonl"
        rm -f "$ports" "$raw"

        naabu -host "$target" -tp ${cfg.topPorts} -s c -rate ${toString cfg.portRate} \
          -duc -silent -o "$ports" >/dev/null 2>&1 || true
        if [ ! -s "$ports" ]; then
          return 1
        fi
        port_count=$(wc -l < "$ports")

        update_templates
        run=$(date -u +%Y%m%dT%H%M%SZ)
        out="${resultsDir}/$run-$target.jsonl"

        # -ni: no interactsh callbacks to public oast servers. Findings go to the file only.
        nuclei -l "$ports" -duc -ni -s ${lib.concatStringsSep "," cfg.severities} ${excludeArgs} \
          -rl ${toString cfg.rateLimit} -c ${toString cfg.concurrency} \
          -jsonl -or -ot -nc -silent -o "$raw" >/dev/null || return 2

        # nuclei only creates the file when something matched
        touch "$raw"
        jq -c --arg target "$target" --argjson accepted ${lib.escapeShellArg (builtins.toJSON cfg.acceptedFindings)} \
          -f ${annotate} "$raw" > "$out.tmp" || return 2
        rm -f "$raw"

        {
          printf 'nuclei_scan_last_success_timestamp_seconds{target="%s"} %s\n' "$target" "$(date +%s)"
          printf 'nuclei_scan_open_ports{target="%s"} %s\n' "$target" "$port_count"
          jq -r -f ${findingMetrics} "$out.tmp" | sort -u
        } | write_prom "${textfileDir}/nuclei-target-$target.prom" || return 2

        findings=$(jq -sr 'map(select(.accepted | not) | .info.severity) | group_by(.) | map("\(length) \(.[0])") | join(", ")' "$out.tmp")
        if [ -s "$out.tmp" ]; then
          mv "$out.tmp" "$out"
        else
          rm -f "$out.tmp"
        fi
        echo "$target: $port_count open ports; open findings: ''${findings:-none}"
      }

      weekly() {
        local targets target rc scanned=0 failed=0
        mapfile -t targets < "${cfg.targetsFile}"
        for target in "''${targets[@]}"; do
          [ -n "$target" ] || continue
          rc=0
          scan_target "$target" || rc=$?
          case $rc in
            0) scanned=$((scanned + 1)) ;;
            1) echo "$target: no open ports, skipped" ;;
            *) failed=$((failed + 1)); echo "$target: scan failed" >&2 ;;
          esac
        done

        if [ "$scanned" -eq 0 ] || [ "$failed" -gt 0 ]; then
          echo "weekly: $scanned scanned, $failed failed" >&2
          write_run_metric 0
          exit 1
        fi
        write_run_metric 1
      }

      # First successful scan of each target per local day; down hosts are retried next poll.
      daily() {
        local target rc failed=0
        for target in ${lib.escapeShellArgs cfg.dailyTargets}; do
          if [ "$(cat "${stateDir}/daily/$target" 2>/dev/null)" = "$today" ]; then
            continue
          fi
          rc=0
          scan_target "$target" || rc=$?
          case $rc in
            0) echo "$today" > "${stateDir}/daily/$target" ;;
            1) ;;
            *) failed=$((failed + 1)); echo "$target: scan failed" >&2 ;;
          esac
        done

        if [ "$failed" -gt 0 ]; then
          write_run_metric 0
          exit 1
        fi
        write_run_metric 1
      }

      # Weekly and daily runs share templates and state; the poller yields to a running scan.
      exec 9>"${stateDir}/lock"
      case $mode in
        weekly)
          flock 9
          weekly
          ;;
        daily)
          if ! flock -n 9; then
            echo "another scan is running; retrying next poll"
            write_run_metric 1
            exit 0
          fi
          daily
          ;;
        *)
          echo "usage: nuclei-scan weekly|daily" >&2
          exit 2
          ;;
      esac
    '';
  };

  serviceConfig = mode: {
    Type = "oneshot";
    User = "nuclei-scan";
    Group = "nuclei-scan";
    StateDirectory = "nuclei-scan";
    StateDirectoryMode = "0750";
    UMask = "0027";
    ExecStart = "${lib.getExe scan} ${mode}";
    TimeoutStartSec = "12h";
    Nice = 10;
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    ReadWritePaths = [ textfileDir ];
  };
in
{
  options.services.nuclei-scan = {
    enable = lib.mkEnableOption "scheduled naabu + nuclei scans of homelab hosts, shipped to Loki";

    targetsFile = lib.mkOption {
      type = lib.types.path;
      description = "File with one always-on target host or IP per line, scanned weekly, e.g. a sops secret.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "Sun 03:00";
      description = "systemd OnCalendar expression for the weekly scan of targetsFile.";
    };

    dailyTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Intermittently online hosts, scanned once per day on the first poll that finds open ports.";
    };

    dailyPollSchedule = lib.mkOption {
      type = lib.types.str;
      default = "*:0/15";
      description = "systemd OnCalendar expression for polling dailyTargets.";
    };

    topPorts = lib.mkOption {
      type = lib.types.enum [ "100" "1000" "full" ];
      default = "1000";
      description = "naabu top-ports set probed on each target.";
    };

    portRate = lib.mkOption {
      type = lib.types.ints.positive;
      default = 500;
      description = "naabu packets per second.";
    };

    severities = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "info" "low" "medium" "high" "critical" ]);
      default = [ "low" "medium" "high" "critical" ];
      description = "nuclei template severities to run and record.";
    };

    excludeTemplateIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "nuclei template IDs never run (-eid), e.g. templates for products not in the fleet.";
    };

    acceptedFindings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "CVE-2019-11248 http://shikisha:9090/debug/pprof/" ];
      description = ''
        Findings as "<template-id> <matched-at>" that stay in Loki, marked accepted,
        but are left out of the nuclei_finding metric and therefore never alert.
      '';
    };

    rateLimit = lib.mkOption {
      type = lib.types.ints.positive;
      default = 50;
      description = "nuclei requests per second.";
    };

    concurrency = lib.mkOption {
      type = lib.types.ints.positive;
      default = 25;
      description = "nuclei templates executed in parallel.";
    };

    retentionDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 90;
      description = "Days to keep result files on disk; Loki retention applies separately.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      users.users.nuclei-scan = {
        isSystemUser = true;
        group = "nuclei-scan";
        home = stateDir;
        extraGroups = [ "promtext" ];
      };
      users.groups.nuclei-scan = { };

      systemd.tmpfiles.rules = [
        "d ${resultsDir} 0750 nuclei-scan nuclei-scan ${toString cfg.retentionDays}d"
      ];

      systemd.services.nuclei-scan = {
        description = "Scan homelab hosts with naabu and nuclei";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        environment.HOME = stateDir;
        serviceConfig = serviceConfig "weekly";
      };

      systemd.timers.nuclei-scan = {
        description = "Scheduled homelab nuclei scan";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };

      # Alloy reads result files through group membership.
      systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "nuclei-scan" ];

      environment.etc."alloy/nuclei.alloy".text = ''
        local.file_match "nuclei" {
          path_targets = [{ __path__ = "${resultsDir}/*.jsonl" }]
        }

        loki.source.file "nuclei" {
          targets    = local.file_match.nuclei.targets
          forward_to = [loki.process.nuclei.receiver]
        }

        loki.process "nuclei" {
          forward_to = [loki.write.default.receiver]

          stage.json {
            expressions = {
              severity    = "info.severity",
              target      = "\"scan-target\"",
              template_id = "\"template-id\"",
              matched_at  = "\"matched-at\"",
              timestamp   = "",
            }
          }

          stage.labels {
            values = { severity = "", target = "" }
          }

          // Per-finding fields stay out of the label index.
          stage.structured_metadata {
            values = { template_id = "", matched_at = "" }
          }

          stage.timestamp {
            source = "timestamp"
            format = "RFC3339Nano"
          }

          stage.static_labels {
            values = { job = "nuclei", host = "${config.networking.hostName}" }
          }
        }
      '';
    }

    (lib.mkIf (cfg.dailyTargets != [ ]) {
      systemd.services.nuclei-scan-daily = {
        description = "Scan intermittently online hosts once per day";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        environment.HOME = stateDir;
        serviceConfig = serviceConfig "daily";
      };

      systemd.timers.nuclei-scan-daily = {
        description = "Poll intermittently online hosts for their daily nuclei scan";
        wantedBy = [ "timers.target" ];
        timerConfig.OnCalendar = cfg.dailyPollSchedule;
      };
    })
  ]);
}
