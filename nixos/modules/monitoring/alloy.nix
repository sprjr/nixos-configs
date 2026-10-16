{ config, lib, ... }:

let
  # shikisha runs Loki locally; every other host reaches it over Tailscale.
  lokiUrl =
    if config.networking.hostName == "shikisha" then
      "http://127.0.0.1:3100/loki/api/v1/push"
    else
      "http://shikisha:3100/loki/api/v1/push";
in
{
  # Logs only; metrics stay pull-based via node-exporter.
  services.alloy.enable = true;

  # grafana-alloy's rpath points at systemd-minimal-libs, which cannot read
  # COMPRESSED-ZSTD journal files; load the full libsystemd instead.
  systemd.services.alloy.environment.LD_LIBRARY_PATH = "${lib.getLib config.systemd.package}/lib";

  environment.etc."alloy/config.alloy".text = ''
    loki.write "default" {
      endpoint {
        url = "${lokiUrl}"
      }
    }

    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }
    }

    loki.source.journal "journal" {
      forward_to    = [loki.write.default.receiver]
      relabel_rules = loki.relabel.journal.rules
      labels        = { job = "systemd-journal", host = "${config.networking.hostName}" }
      max_age       = "12h"
    }
  '';
}
