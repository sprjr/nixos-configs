{ config, pkgs, lib, ... }:

let
  cfg = config.services.nuclei-scan;
  stateDir = "/var/lib/nuclei-scan";
  resultsDir = "${stateDir}/results";

  # naabu finds open ports; nuclei scans each host:port. Results land atomically for Alloy.
  scan = pkgs.writeShellApplication {
    name = "nuclei-scan";
    runtimeInputs = [ pkgs.naabu pkgs.nuclei pkgs.coreutils ];
    text = ''
      run=$(date -u +%Y%m%dT%H%M%SZ)
      ports="${stateDir}/ports.txt"

      naabu -list "${cfg.targetsFile}" -tp ${cfg.topPorts} -s c -rate ${toString cfg.portRate} \
        -duc -silent -o "$ports" >/dev/null

      if [ ! -s "$ports" ]; then
        echo "naabu found no open ports on any target" >&2
        exit 1
      fi

      # -ni: no interactsh callbacks to public oast servers. Findings go to the file only.
      nuclei -l "$ports" -duc -ni -s ${lib.concatStringsSep "," cfg.severities} \
        -rl ${toString cfg.rateLimit} -c ${toString cfg.concurrency} \
        -jsonl -or -ot -nc -silent -o "${resultsDir}/$run.jsonl.tmp" >/dev/null

      # nuclei only creates the file when something matched
      if [ -f "${resultsDir}/$run.jsonl.tmp" ]; then
        mv "${resultsDir}/$run.jsonl.tmp" "${resultsDir}/$run.jsonl"
      fi
    '';
  };
in
{
  options.services.nuclei-scan = {
    enable = lib.mkEnableOption "scheduled naabu + nuclei scans of homelab hosts, shipped to Loki";

    targetsFile = lib.mkOption {
      type = lib.types.path;
      description = "File with one target host or IP per line, e.g. a sops secret.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "Sun 03:00";
      description = "systemd OnCalendar expression for scan runs.";
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

  config = lib.mkIf cfg.enable {
    users.users.nuclei-scan = {
      isSystemUser = true;
      group = "nuclei-scan";
      home = stateDir;
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
      serviceConfig = {
        Type = "oneshot";
        User = "nuclei-scan";
        Group = "nuclei-scan";
        StateDirectory = "nuclei-scan";
        StateDirectoryMode = "0750";
        UMask = "0027";
        # Template refresh failure falls back to the existing set.
        ExecStartPre = "-${pkgs.nuclei}/bin/nuclei -ut -ud ${stateDir}/nuclei-templates";
        ExecStart = lib.getExe scan;
        TimeoutStartSec = "12h";
        Nice = 10;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
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
            target      = "host",
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
  };
}
