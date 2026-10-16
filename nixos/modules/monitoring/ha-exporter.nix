{ config, pkgs, lib, ... }:

let
  cfg = config.services.ha-exporter;

  textfileDir = "/var/lib/prometheus-node-exporter/textfile";

  # Home Assistant API. Defaults to loopback port 8123 on the host running the
  # exporter (shikisha runs HA). Can be overridden per-host if needed.
  apiBase = cfg.apiUrl;

  # Entities whose availability is the "is the Frigate/HA pipeline healthy"
  # signal. camera.* and binary_sensor.front_door_person_occupancy going
  # unavailable is exactly the silent brittleness we want surfaced.
  entityList = cfg.entities;

  exporter = pkgs.writeScript "ha-exporter.py" ''
    #!${pkgs.python3}/bin/python3
    import json
    import os
    import time
    import urllib.request

    PROM_FILE = "${textfileDir}/ha.prom"
    TMP_FILE = PROM_FILE + ".tmp"
    API_URL = "${apiBase}/api/states"
    TOKEN_FILE = "${if cfg.apiTokenFile != null then cfg.apiTokenFile else ""}"
    ENTITIES = [ ${builtins.concatStringsSep ", " (map (e: ''"${e}"'') entityList)} ]

    def prom_label(s):
        return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

    lines = []
    token = None
    if TOKEN_FILE and os.path.exists(TOKEN_FILE):
        try:
            with open(TOKEN_FILE) as f:
                token = f.read().strip()
        except Exception:
            token = None

    up = 0
    latency = 0.0
    states = {}
    try:
        req = urllib.request.Request(API_URL)
        if token:
            req.add_header("Authorization", "Bearer " + token)
        t0 = time.monotonic()
        with urllib.request.urlopen(req, timeout=10) as resp:
            latency = time.monotonic() - t0
            data = json.loads(resp.read().decode())
            up = 1
    except Exception:
        data = []

    # Map entity_id -> state string for fast lookup.
    for ent in data:
        eid = ent.get("entity_id", "")
        if eid:
            states[eid] = ent.get("state", "unknown")

    lines.append("# HELP ha_up Whether the Home Assistant API is reachable")
    lines.append("# TYPE ha_up gauge")
    lines.append(f"ha_up {up}")
    lines.append("# HELP ha_api_latency_seconds Home Assistant API round-trip latency")
    lines.append("# TYPE ha_api_latency_seconds gauge")
    lines.append(f"ha_api_latency_seconds {latency:.6f}")
    lines.append("# HELP ha_entities_total Number of states returned by HA")
    lines.append("# TYPE ha_entities_total gauge")
    lines.append(f"ha_entities_total {len(data)}")

    # Per-entity availability gauge: 1 if the entity is present and not
    # "unavailable"/"unknown". Exposes state as a label so dashboards can show
    # occupancy too. Missing entities (API returned without them) = 0.
    lines.append("# HELP ha_entity_available Whether a tracked entity is live (1) or unavailable/missing (0)")
    lines.append("# TYPE ha_entity_available gauge")
    for ent in ENTITIES:
        st = states.get(ent, "missing")
        ok = 1 if (st not in ("unavailable", "unknown", "missing")) else 0
        lines.append(
            f'ha_entity_available{{entity="{prom_label(ent)}",state="{prom_label(st)}"}} {ok}'
        )

    # Overall integration health: fraction of *tracked* entities currently live.
    if ENTITIES:
        live = sum(1 for ent in ENTITIES if states.get(ent, "missing") not in ("unavailable", "unknown", "missing"))
        lines.append("# HELP ha_tracked_entities_up Count of tracked entities currently live")
        lines.append("# TYPE ha_tracked_entities_up gauge")
        lines.append(f"ha_tracked_entities_up {live}")

    with open(TMP_FILE, "w") as f:
        f.write("\n".join(lines) + "\n")
    os.rename(TMP_FILE, PROM_FILE)
  '';
in
{
  options.services.ha-exporter = {
    enable = lib.mkEnableOption "Home Assistant Prometheus textfile exporter";

    apiUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8123";
      description = "Base URL of the Home Assistant API (no trailing slash).";
    };

    apiTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file containing a Home Assistant long-lived access token. When
        set, entity availability and state are collected (the full feature set).
        When null, only unauthenticated connectivity/latency metrics are
        collected. Typically wired to the `ha_token` sops secret.
      '';
    };

    entities = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "camera.front_door"
        "camera.garage"
        "binary_sensor.front_door_person_occupancy"
        "switch.front_door_detect"
      ];
      description = "HA entity IDs to track availability for.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ha-exporter = {
      description = "Export Home Assistant entity availability as Prometheus textfile metrics";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = exporter;
      };
      # Don't let transient HA blips flap the textfile; keep the last good write.
      serviceConfig.Delegate = false;
    };

    systemd.timers.ha-exporter = {
      description = "Run ha-exporter periodically";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
      };
    };
  };
}
