# Grafana dashboard for nuclei-scan findings (Loki, job="nuclei")
let
  ds = {
    type = "loki";
    uid = "loki";
  };

  panel =
    id: type: title: gridPos: targets: extra:
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
  # One weekly scan plus schedule jitter.
  time = {
    from = "now-8d";
    to = "now";
  };
  timezone = "browser";
  panels = [
    (panel 1 "stat" "Findings by severity (range)" { h = 5; w = 24; x = 0; y = 0; }
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
    (panel 2 "barchart" "Findings by target (range)" { h = 9; w = 24; x = 0; y = 5; }
      [
        ((instant (target "A" ''sum by (target) (count_over_time({job="nuclei"}[$__range]))'' "{{target}}")) // {
          format = "table";
        })
      ]
      { }
    )
    (panel 3 "logs" "Findings" { h = 16; w = 24; x = 0; y = 14; }
      [
        (target "A" ''{job="nuclei"} | json | line_format "[{{.info_severity}}] {{.info_name}} - {{.matched_at}} ({{.template_id}})"'' "")
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
