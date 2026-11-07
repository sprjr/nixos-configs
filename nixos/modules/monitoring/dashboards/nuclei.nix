# Grafana dashboard for nuclei-scan: current state (Prometheus textfile metrics) and finding history (Loki, job="nuclei")
let
  loki = {
    type = "loki";
    uid = "loki";
  };

  prom = {
    type = "prometheus";
    uid = "prometheus";
  };

  panel =
    ds: id: type: title: gridPos: targets: extra:
    {
      inherit
        id
        type
        title
        gridPos
        ;
      datasource = ds;
      targets = map (t: t // { datasource = ds; }) targets;
    }
    // extra;

  target = refId: expr: legendFormat: { inherit refId expr legendFormat; };

  instant = t: t // { queryType = "instant"; };

  severityColors = {
    critical = "dark-red";
    high = "red";
    medium = "orange";
    low = "yellow";
  };
in
{
  uid = "nuclei";
  title = "Nuclei Findings";
  tags = [
    "nixos"
    "homelab"
    "security"
  ];
  schemaVersion = 39;
  version = 1;
  editable = false;
  refresh = "5m";
  # Covers one weekly scan plus schedule jitter.
  time = {
    from = "now-8d";
    to = "now";
  };
  timezone = "browser";
  panels = [
    (panel prom 4 "table" "Open findings (latest scan per target)" { h = 9; w = 24; x = 0; y = 0; }
      [
        ((instant (target "A" "nuclei_finding" "")) // {
          format = "table";
        })
      ]
      {
        transformations = [
          {
            id = "organize";
            options = {
              excludeByName = {
                Time = true;
                Value = true;
                __name__ = true;
                instance = true;
                job = true;
              };
              indexByName = {
                target = 0;
                finding_severity = 1;
                name = 2;
                matched_at = 3;
                template_id = 4;
              };
            };
          }
        ];
      }
    )
    (panel prom 5 "table" "Targets" { h = 7; w = 24; x = 0; y = 9; }
      [
        ((instant (target "A" "time() - nuclei_scan_last_success_timestamp_seconds" "")) // {
          format = "table";
        })
        ((instant (target "B" "nuclei_scan_open_ports" "")) // {
          format = "table";
        })
      ]
      {
        transformations = [
          {
            id = "merge";
            options = { };
          }
          {
            id = "organize";
            options = {
              excludeByName = {
                Time = true;
                instance = true;
                job = true;
              };
              renameByName = {
                "Value #A" = "Since last scan";
                "Value #B" = "Open ports";
              };
            };
          }
        ];
        fieldConfig = {
          defaults = { };
          overrides = [
            {
              matcher = {
                id = "byName";
                options = "Since last scan";
              };
              properties = [
                {
                  id = "unit";
                  value = "s";
                }
              ];
            }
          ];
        };
      }
    )
    (panel loki 1 "stat" "Findings by severity (range)" { h = 5; w = 24; x = 0; y = 16; }
      [ (instant (target "A" ''sum by (severity) (count_over_time({job="nuclei"}[$__range]))'' "{{severity}}")) ]
      {
        fieldConfig = {
          defaults.color.mode = "fixed";
          overrides = builtins.attrValues (
            builtins.mapAttrs (sev: color: {
              matcher = {
                id = "byName";
                options = sev;
              };
              properties = [
                {
                  id = "color";
                  value = {
                    mode = "fixed";
                    fixedColor = color;
                  };
                }
              ];
            }) severityColors
          );
        };
      }
    )
    (panel loki 2 "barchart" "Findings by target (range)" { h = 9; w = 24; x = 0; y = 21; }
      [
        ((instant (target "A" ''sum by (target) (count_over_time({job="nuclei"}[$__range]))'' "{{target}}")) // {
          format = "table";
        })
      ]
      { }
    )
    (panel loki 3 "logs" "Findings" { h = 16; w = 24; x = 0; y = 30; }
      [
        (target "A" ''{job="nuclei"} | json | line_format `[{{.info_severity}}] {{.scan_target}}: {{.info_name}} - {{.matched_at}} ({{.template_id}}){{if eq .accepted "true"}} [accepted]{{end}}`'' "")
      ]
      {
        options = {
          showTime = true;
          sortOrder = "Descending";
          wrapLogMessage = true;
        };
      }
    )
  ];
}
