# Grafana dashboard for frigate-analyzer metrics (badgey:9465)
let
  ds = {
    type = "prometheus";
    uid = "prometheus";
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
in
{
  uid = "frigate-analyzer";
  title = "Frigate Analyzer";
  tags = [
    "nixos"
    "homelab"
    "frigate"
  ];
  schemaVersion = 39;
  version = 1;
  editable = false;
  refresh = "1m";
  time = {
    from = "now-7d";
    to = "now";
  };
  timezone = "browser";
  panels = [
    (panel 1 "stat" "MQTT connected" { h = 4; w = 6; x = 0; y = 0; }
      [ (target "A" "frigate_analyzer_mqtt_connected" "") ]
      {
        fieldConfig.defaults.mappings = [
          {
            type = "value";
            options = {
              "0" = { text = "down"; color = "red"; };
              "1" = { text = "up"; color = "green"; };
            };
          }
        ];
      }
    )
    (panel 2 "stat" "Package present" { h = 4; w = 6; x = 6; y = 0; }
      [ (target "A" "frigate_analyzer_package_present" "{{camera}}") ]
      {
        fieldConfig.defaults.mappings = [
          {
            type = "value";
            options = {
              "0" = { text = "no"; color = "green"; };
              "1" = { text = "yes"; color = "orange"; };
            };
          }
        ];
      }
    )
    (panel 3 "stat" "Events (range)" { h = 4; w = 6; x = 12; y = 0; }
      [ (target "A" "sum(increase(frigate_analyzer_events_total[$__range]))" "") ]
      { }
    )
    (panel 4 "stat" "Queue depth" { h = 4; w = 6; x = 18; y = 0; }
      [ (target "A" "frigate_analyzer_queue_depth" "") ]
      { }
    )
    (panel 5 "timeseries" "Events per hour by camera" { h = 8; w = 12; x = 0; y = 4; }
      [ (target "A" "sum by (camera, source) (increase(frigate_analyzer_events_total[1h]))" "{{camera}} {{source}}") ]
      { }
    )
    (panel 6 "timeseries" "Rule findings per hour" { h = 8; w = 12; x = 12; y = 4; }
      [ (target "A" "sum by (rule) (increase(frigate_analyzer_findings_total[1h]))" "{{rule}}") ]
      { }
    )
    (panel 7 "barchart" "People by apparent purpose (range)" { h = 8; w = 12; x = 0; y = 12; }
      [
        ((target "A" "sum by (purpose) (increase(frigate_analyzer_people_total[$__range]))" "{{purpose}}") // {
          instant = true;
          format = "table";
        })
      ]
      { }
    )
    (panel 8 "barchart" "Vehicles by id (range)" { h = 8; w = 12; x = 12; y = 12; }
      [
        ((target "A" "sum by (vehicle) (increase(frigate_analyzer_vehicles_total[$__range]))" "{{vehicle}}") // {
          instant = true;
          format = "table";
        })
      ]
      { }
    )
    (panel 9 "timeseries" "Inference latency" { h = 8; w = 12; x = 0; y = 20; }
      [
        (target "A" "histogram_quantile(0.5, sum by (le) (rate(frigate_analyzer_inference_seconds_bucket[15m])))" "p50")
        (target "B" "histogram_quantile(0.95, sum by (le) (rate(frigate_analyzer_inference_seconds_bucket[15m])))" "p95")
      ]
      { fieldConfig.defaults.unit = "s"; }
    )
    (panel 10 "timeseries" "Failures per hour" { h = 8; w = 12; x = 12; y = 20; }
      [
        (target "A" "sum by (channel) (increase(frigate_analyzer_notifications_total{status=\"error\"}[1h]))" "notify {{channel}}")
        (target "B" "sum(increase(frigate_analyzer_inference_failures_total[1h]))" "inference")
      ]
      { }
    )
  ];
}
