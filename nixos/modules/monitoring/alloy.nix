{ config, ... }:

let
  # shikisha runs Loki locally; every other host reaches it over Tailscale.
  lokiUrl =
    if config.networking.hostName == "shikisha" then
      "http://127.0.0.1:3100/loki/api/v1/push"
    else
      "http://shikisha:3100/loki/api/v1/push";
in
{
  # Alloy replaces promtail, which reached end-of-life in March 2026. Logs only; metrics stay
  # pull-based via node-exporter so Prometheus does not need a remote-write receiver.
  # The NixOS module runs alloy as a DynamicUser in the systemd-journal group, so journal
  # reads need no extra permission wiring.
  services.alloy.enable = true;

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
