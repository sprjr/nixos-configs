{ config, pkgs, lib, ... }:

let
  cfg = config.services.satisfactory-exporter;

  textfileDir = "/var/lib/prometheus-node-exporter/textfile";

  # The Satisfactory dedicated server exposes a self-signed HTTPS REST API on the
  # game port (7777). Every call is a POST with a `function` name and `data`
  # object; admin functions require a Bearer application token. We run on the
  # host and reach the container via loopback, so the API is never exposed
  # beyond the host. The token is supplied via `apiTokenFile` (typically a sops
  # secret); when absent, only unauthenticated metrics (up/health/latency) are
  # collected.
  apiUrl = "https://127.0.0.1:7777/api/v1";

  satisfactoryExporter = pkgs.writeScript "satisfactory-exporter.py" ''
    #!${pkgs.python3}/bin/python3
    import json
    import os
    import ssl
    import sys
    import time
    import urllib.request
    from datetime import datetime

    PROM_FILE = "${textfileDir}/satisfactory.prom"
    TMP_FILE = PROM_FILE + ".tmp"
    TOKEN_FILE = "${cfg.apiTokenFile}"
    API_URL = "${apiUrl}"

    # Self-signed cert; the API is loopback-only so we skip verification.
    _ctx = ssl.create_default_context()
    _ctx.check_hostname = False
    _ctx.verify_mode = ssl.CERT_NONE


    def prom_escape(s):
        return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


    def api_call(function, data=None, token=None):
        body = json.dumps({"function": function, "data": data or {}}).encode()
        req = urllib.request.Request(
            API_URL,
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        if token:
            req.add_header("Authorization", "Bearer " + token)
        start = time.monotonic()
        with urllib.request.urlopen(req, context=_ctx, timeout=10) as resp:
            latency = time.monotonic() - start
            return json.loads(resp.read().decode()), latency


    def parse_save_dt(s):
        # "2024.09.28-04.00.32" -> epoch seconds
        try:
            return datetime.strptime(s, "%Y.%m.%d-%H.%M.%S").timestamp()
        except Exception:
            return 0


    lines = []
    token = None
    if TOKEN_FILE and os.path.exists(TOKEN_FILE):
        try:
            with open(TOKEN_FILE) as f:
                token = f.read().strip()
        except Exception:
            token = None

    # --- HealthCheck (no auth) ---
    up = 0
    health = 0
    latency = 0.0
    try:
        data, latency = api_call("HealthCheck")
        up = 1
        health = 1 if data.get("data", {}).get("health") == "healthy" else 0
    except Exception:
        pass

    lines.append("# HELP satisfactory_up Whether the Satisfactory API is reachable")
    lines.append("# TYPE satisfactory_up gauge")
    lines.append(f"satisfactory_up {up}")
    lines.append("# HELP satisfactory_health API health (1=healthy 0=slow)")
    lines.append("# TYPE satisfactory_health gauge")
    lines.append(f"satisfactory_health {health}")
    lines.append("# HELP satisfactory_api_latency_seconds API round-trip latency")
    lines.append("# TYPE satisfactory_api_latency_seconds gauge")
    lines.append(f"satisfactory_api_latency_seconds {latency:.6f}")

    # --- QueryServerState (bearer) ---
    if token:
        try:
            data, _ = api_call("QueryServerState", token=token)
            gs = data.get("data", {}).get("serverGameState", {})
            lines.append("# HELP satisfactory_players_connected Players currently connected")
            lines.append("# TYPE satisfactory_players_connected gauge")
            lines.append(f"satisfactory_players_connected {gs.get('numConnectedPlayers', 0)}")
            lines.append("# HELP satisfactory_player_limit Max players")
            lines.append("# TYPE satisfactory_player_limit gauge")
            lines.append(f"satisfactory_player_limit {gs.get('playerLimit', 0)}")
            lines.append("# HELP satisfactory_game_running Whether a save is loaded (1=yes 0=no)")
            lines.append("# TYPE satisfactory_game_running gauge")
            lines.append(f"satisfactory_game_running {1 if gs.get('isGameRunning') else 0}")
            lines.append("# HELP satisfactory_game_paused Whether the game is paused (1=yes 0=no)")
            lines.append("# TYPE satisfactory_game_paused gauge")
            lines.append(f"satisfactory_game_paused {1 if gs.get('isGamePaused') else 0}")
            lines.append("# HELP satisfactory_average_tick_rate Server tick rate (ticks/s)")
            lines.append("# TYPE satisfactory_average_tick_rate gauge")
            lines.append(f"satisfactory_average_tick_rate {gs.get('averageTickRate', 0)}")
            lines.append("# HELP satisfactory_total_game_duration_seconds Time current save has been loaded")
            lines.append("# TYPE satisfactory_total_game_duration_seconds gauge")
            lines.append(f"satisfactory_total_game_duration_seconds {gs.get('totalGameDuration', 0)}")
            lines.append("# HELP satisfactory_tech_tier Max unlocked tech tier")
            lines.append("# TYPE satisfactory_tech_tier gauge")
            lines.append(f"satisfactory_tech_tier {gs.get('techTier', 0)}")
            lines.append("# HELP satisfactory_session_info Current session")
            lines.append("# TYPE satisfactory_session_info gauge")
            lines.append(
                f'satisfactory_session_info{{session="{prom_escape(gs.get("activeSessionName", ""))}",'
                f'phase="{prom_escape(gs.get("gamePhase", ""))}"}} 1'
            )
        except Exception:
            pass

    # --- EnumerateSessions (bearer, admin) -> save verification ---
    if token:
        try:
            data, _ = api_call("EnumerateSessions", token=token)
            sessions = data.get("data", {}).get("sessions", [])
            save_count = 0
            last_save = 0
            for s in sessions:
                sname = s.get("sessionName", "")
                for h in s.get("saveHeaders", []):
                    save_count += 1
                    ts = parse_save_dt(h.get("saveDateTime", ""))
                    if ts > last_save:
                        last_save = ts
                    lines.append(
                        f'satisfactory_save_info{{session="{prom_escape(sname)}",'
                        f'save="{prom_escape(h.get("saveName", ""))}",'
                        f'play_seconds="{h.get("playDurationSeconds", 0)}"}} '
                        f"{int(ts)}"
                    )
            lines.append("# HELP satisfactory_save_count Total save files on server")
            lines.append("# TYPE satisfactory_save_count gauge")
            lines.append(f"satisfactory_save_count {save_count}")
            lines.append("# HELP satisfactory_last_save_timestamp_seconds Epoch of newest save file")
            lines.append("# TYPE satisfactory_last_save_timestamp_seconds gauge")
            lines.append(f"satisfactory_last_save_timestamp_seconds {int(last_save)}")
        except Exception:
            pass

    with open(TMP_FILE, "w") as f:
        f.write("\n".join(lines) + "\n")
    os.rename(TMP_FILE, PROM_FILE)
  '';
in
{
  options.services.satisfactory-exporter = {
    enable = lib.mkEnableOption "Satisfactory dedicated server Prometheus exporter";

    apiTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file containing the Satisfactory API application token. When
        set, admin metrics (players, session state, save verification) are
        collected. When null, only unauthenticated metrics (up/health/latency)
        are collected. Typically wired to a sops secret, e.g.
        `config.sops.secrets."satisfactory/api-token".path`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.satisfactory-exporter = {
      description = "Export Satisfactory server state as Prometheus textfile metrics";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = satisfactoryExporter;
      };
    };

    systemd.timers.satisfactory-exporter = {
      description = "Run satisfactory-exporter periodically";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
      };
    };
  };
}
