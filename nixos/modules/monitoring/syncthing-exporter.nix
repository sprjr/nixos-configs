{ config, pkgs, ... }:

let
  textfileDir = "/var/lib/prometheus-node-exporter/textfile";

  syncthingExporter = pkgs.writeScript "syncthing-exporter.py" ''
    #!${pkgs.python3}/bin/python3
    import json, os, subprocess, sys
    from urllib.request import Request, urlopen
    from urllib.error import URLError

    PROM_FILE = "${textfileDir}/syncthing.prom"
    TMP_FILE = PROM_FILE + ".tmp"
    CONFIG_XML = "${config.services.syncthing.configDir}/config.xml"
    API_BASE = "http://127.0.0.1:8384"


    def prom_escape(s):
        return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


    def api_get(path, api_key):
        req = Request(API_BASE + path, headers={"X-API-Key": api_key})
        return json.loads(urlopen(req, timeout=10).read())


    def write_and_exit(lines):
        with open(TMP_FILE, "w") as f:
            f.write("\n".join(lines) + "\n")
        os.rename(TMP_FILE, PROM_FILE)
        sys.exit(0)


    lines = []

    # Extract API key from Syncthing config.xml
    try:
        r = subprocess.run(
            ["xmllint", "--xpath", "string(//configuration/gui/apikey)", CONFIG_XML],
            capture_output=True, text=True, timeout=5,
        )
        if r.returncode != 0 or not r.stdout.strip():
            raise RuntimeError("no api key")
        api_key = r.stdout.strip()
    except Exception:
        lines.append("# HELP syncthing_up Whether the Syncthing API is reachable")
        lines.append("# TYPE syncthing_up gauge")
        lines.append("syncthing_up 0")
        write_and_exit(lines)

    # Service status
    try:
        status = api_get("/rest/system/status", api_key)
    except (URLError, Exception):
        lines.append("# HELP syncthing_up Whether the Syncthing API is reachable")
        lines.append("# TYPE syncthing_up gauge")
        lines.append("syncthing_up 0")
        write_and_exit(lines)

    lines.append("# HELP syncthing_up Whether the Syncthing API is reachable")
    lines.append("# TYPE syncthing_up gauge")
    lines.append("syncthing_up 1")

    lines.append("# HELP syncthing_uptime_seconds Syncthing process uptime in seconds")
    lines.append("# TYPE syncthing_uptime_seconds gauge")
    lines.append(f"syncthing_uptime_seconds {status.get('uptime', 0)}")

    my_id = status.get("myID", "")

    # Device connectivity
    try:
        devices_config = api_get("/rest/config/devices", api_key)
        connections = api_get("/rest/system/connections", api_key)
        conn_map = connections.get("connections", {})

        device_names = {
            d["deviceID"]: d.get("name", d["deviceID"][:8])
            for d in devices_config
            if d["deviceID"] != my_id
        }

        connected_count = 0

        lines.append("# HELP syncthing_device_connected Whether a remote device is connected")
        lines.append("# TYPE syncthing_device_connected gauge")
        for dev_id, name in sorted(device_names.items(), key=lambda x: x[1]):
            is_connected = 1 if conn_map.get(dev_id, {}).get("connected", False) else 0
            connected_count += is_connected
            lines.append(
                f'syncthing_device_connected{{name="{prom_escape(name)}"}} {is_connected}'
            )

        lines.append("# HELP syncthing_connected_devices Number of connected remote devices")
        lines.append("# TYPE syncthing_connected_devices gauge")
        lines.append(f"syncthing_connected_devices {connected_count}")

        lines.append("# HELP syncthing_configured_devices Number of configured remote devices")
        lines.append("# TYPE syncthing_configured_devices gauge")
        lines.append(f"syncthing_configured_devices {len(device_names)}")
    except Exception:
        pass

    # Folder sync state
    STATE_MAP = {
        "idle": 1,
        "scanning": 2,
        "scan-waiting": 2,
        "cleaning": 2,
        "clean-waiting": 2,
        "syncing": 3,
        "sync-preparing": 3,
        "sync-waiting": 3,
    }

    try:
        folders_config = api_get("/rest/config/folders", api_key)

        lines.append("# HELP syncthing_folder_state Folder sync state (0=error 1=idle 2=scanning 3=syncing)")
        lines.append("# TYPE syncthing_folder_state gauge")
        lines.append("# HELP syncthing_folder_need_files Number of files needing sync in folder")
        lines.append("# TYPE syncthing_folder_need_files gauge")
        lines.append("# HELP syncthing_folder_errors Number of pull errors in folder")
        lines.append("# TYPE syncthing_folder_errors gauge")

        for folder in folders_config:
            fid = folder["id"]
            try:
                db = api_get(f"/rest/db/status?folder={fid}", api_key)
            except Exception:
                lines.append(f'syncthing_folder_state{{folder="{prom_escape(fid)}"}} 0')
                lines.append(f'syncthing_folder_need_files{{folder="{prom_escape(fid)}"}} 0')
                lines.append(f'syncthing_folder_errors{{folder="{prom_escape(fid)}"}} 0')
                continue

            state_val = STATE_MAP.get(db.get("state", ""), 0)
            lines.append(f'syncthing_folder_state{{folder="{prom_escape(fid)}"}} {state_val}')
            lines.append(f'syncthing_folder_need_files{{folder="{prom_escape(fid)}"}} {db.get("needFiles", 0)}')
            lines.append(f'syncthing_folder_errors{{folder="{prom_escape(fid)}"}} {db.get("errors", 0)}')
    except Exception:
        pass

    write_and_exit(lines)
  '';
in
{
  systemd.services.syncthing-exporter = {
    description = "Export Syncthing status as Prometheus textfile metrics";
    after = [ "syncthing.service" ];
    path = [ pkgs.libxml2 ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${syncthingExporter}";
    };
  };

  systemd.timers.syncthing-exporter = {
    description = "Run syncthing-exporter periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "60s";
    };
  };
}
