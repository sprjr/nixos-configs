{ config, lib, ... }:

let
  cfg = config.services.alloy-syslog;
in
{
  options.services.alloy-syslog = {
    enable = lib.mkEnableOption "syslog ingestion via Alloy";

    rfc3164Port = lib.mkOption {
      type = lib.types.port;
      default = 5140;
      description = "Port for RFC3164 (BSD syslog) senders.";
    };

    rfc5424Port = lib.mkOption {
      type = lib.types.port;
      default = 5141;
      description = "Port for RFC5424 senders.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."alloy/syslog.alloy".text = ''
      loki.relabel "syslog" {
        forward_to = []

        rule {
          source_labels = ["__syslog_message_hostname"]
          target_label  = "host"
        }

        rule {
          source_labels = ["__syslog_message_severity"]
          target_label  = "level"
        }

        rule {
          source_labels = ["__syslog_message_app_name"]
          target_label  = "app"
        }

        rule {
          source_labels = ["__syslog_message_facility"]
          target_label  = "facility"
        }

        rule {
          source_labels = ["__syslog_connection_ip_address"]
          target_label  = "source"
        }
      }

      loki.source.syslog "net" {
        listener {
          address       = "0.0.0.0:${toString cfg.rfc3164Port}"
          protocol      = "udp"
          syslog_format = "rfc3164"
          labels        = { job = "syslog" }
        }

        listener {
          address       = "0.0.0.0:${toString cfg.rfc3164Port}"
          protocol      = "tcp"
          syslog_format = "rfc3164"
          labels        = { job = "syslog" }
        }

        listener {
          address       = "0.0.0.0:${toString cfg.rfc5424Port}"
          protocol      = "udp"
          syslog_format = "rfc5424"
          labels        = { job = "syslog" }
        }

        listener {
          address       = "0.0.0.0:${toString cfg.rfc5424Port}"
          protocol      = "tcp"
          syslog_format = "rfc5424"
          labels        = { job = "syslog" }
        }

        relabel_rules = loki.relabel.syslog.rules
        forward_to    = [loki.write.default.receiver]
      }
    '';

    networking.firewall = {
      allowedTCPPorts = [ cfg.rfc3164Port cfg.rfc5424Port ];
      allowedUDPPorts = [ cfg.rfc3164Port cfg.rfc5424Port ];
    };
  };
}
