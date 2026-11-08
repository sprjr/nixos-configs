{ pkgs }:

pkgs.writers.writePython3Bin "frigate-analyzer-mcp"
  {
    libraries = with pkgs.python3Packages; [
      mcp
      pyyaml
    ];
    doCheck = false;
  }
  ''
    import argparse
    import json
    import os
    import sqlite3
    import urllib.request
    from contextlib import closing
    from datetime import datetime
    from pathlib import Path

    import yaml
    from mcp.server.fastmcp import FastMCP, Image

    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", type=int, required=True)
    args = parser.parse_args()

    CFG = json.loads(Path(args.config).read_text())
    DB = CFG["db"]
    SCHEMA = Path(CFG["schema"]).read_text()
    MAX_ROWS = 500

    EVENT_COLUMNS = (
        "e.id, e.local_time, e.camera, e.source, e.frigate_severity, e.labels, e.zones, e.plates, "
        "e.vehicles, e.package_state, e.summary, e.error, e.pinned, e.pin_reason, e.image_pruned, "
        "(SELECT json_group_array(rule_id) FROM findings f WHERE f.event_id = e.id) AS rules"
    )
    JSON_FIELDS = ("labels", "zones", "plates", "vehicles", "rules", "snapshots", "analysis")

    GROUPS = {
        "hour": ("e.local_hour", ""),
        "weekday": ("e.weekday", ""),
        "day": ("date(e.local_time)", ""),
        "camera": ("e.camera", ""),
        "rule": ("f.rule_id", "JOIN findings f ON f.event_id = e.id"),
        "purpose": ("json_extract(p.value, '$.apparent_purpose')", "JOIN json_each(e.analysis, '$.people') p"),
        "vehicle": ("coalesce(json_extract(v.value, '$.vehicle_id'), 'unknown')", "JOIN json_each(e.vehicles) v"),
        "package_state": ("e.package_state", ""),
    }

    mcp = FastMCP("frigate-analyzer", host=args.host, port=args.port)


    def ro():
        conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True, timeout=10)
        conn.row_factory = sqlite3.Row
        return conn


    def to_epoch(value):
        if value is None:
            return None
        try:
            return float(value)
        except ValueError:
            return datetime.fromisoformat(value).timestamp()


    def row_dict(row):
        out = dict(row)
        for key in JSON_FIELDS:
            if isinstance(out.get(key), str):
                out[key] = json.loads(out[key])
        return out


    def filters(start, end, camera, rule_id, label, vehicle_id, text, pinned):
        where, params = [], []
        if start is not None:
            where.append("e.started_at >= ?")
            params.append(to_epoch(start))
        if end is not None:
            where.append("e.started_at < ?")
            params.append(to_epoch(end))
        if camera:
            where.append("e.camera = ?")
            params.append(camera)
        if rule_id:
            where.append("EXISTS (SELECT 1 FROM findings f2 WHERE f2.event_id = e.id AND f2.rule_id = ?)")
            params.append(rule_id)
        if label:
            where.append("EXISTS (SELECT 1 FROM json_each(e.labels) WHERE value = ?)")
            params.append(label)
        if vehicle_id:
            where.append("EXISTS (SELECT 1 FROM json_each(e.vehicles) WHERE json_extract(value, '$.vehicle_id') = ?)")
            params.append(vehicle_id)
        if text:
            where.append("(e.summary LIKE ? OR e.analysis LIKE ?)")
            params += [f"%{text}%", f"%{text}%"]
        if pinned is not None:
            where.append("e.pinned = ?")
            params.append(int(pinned))
        return (" WHERE " + " AND ".join(where)) if where else "", params


    @mcp.tool()
    def describe() -> dict:
        """Database schema, configured rule ids and known vehicle ids.

        Call this first. Times are stored as unix epoch (started_at) and local ISO 8601
        (local_time, America/Denver). analysis holds the raw VLM JSON: people[] with
        approaching_door, apparent_purpose, carrying_package, uniform_or_logo; vehicles[];
        packages_visible; lighting; summary.
        """
        rules_path = Path(os.environ.get("CREDENTIALS_DIRECTORY", "/nonexistent")) / "rules"
        doc = yaml.safe_load(rules_path.read_text()) if rules_path.exists() else {}
        doc = doc or {}
        return {
            "schema": SCHEMA,
            "rules": [{"id": r.get("id"), "description": r.get("description"), "severity": r.get("severity"),
                       "when": r.get("when")} for r in doc.get("rules", [])],
            "vehicles": [{"id": v.get("id"), "name": v.get("name"), "description": v.get("description")}
                         for v in doc.get("vehicles", [])],
            "group_by_options": sorted(GROUPS),
            "cameras": sorted(CFG["camera_context"]),
        }


    @mcp.tool()
    def check_camera(camera: str, question: str | None = None, notify: bool = True) -> list:
        """Grab the current frame from a camera and describe it now, without waiting for an event.

        camera: a name from describe()["cameras"] (e.g. front_door, garage).
        question: optional specific question, answered in the "answer" field.
        notify: also push the snapshot and description through the enabled notifiers (ntfy etc.).
        Takes 5-60 s. The result is stored as a source=manual event.
        """
        body = json.dumps({"camera": camera, "question": question, "notify": notify}).encode()
        req = urllib.request.Request(f"http://127.0.0.1:{CFG['control_port']}/assess", data=body,
                                     headers={"Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(req, timeout=310) as resp:
            result = json.loads(resp.read())
        out = [json.dumps(result)]
        snapshot = result.get("snapshot")
        if snapshot and Path(snapshot).exists():
            out.append(Image(data=Path(snapshot).read_bytes(), format="jpeg"))
        return out


    @mcp.tool()
    def query_events(start: str | None = None, end: str | None = None, camera: str | None = None,
                     rule_id: str | None = None, label: str | None = None, vehicle_id: str | None = None,
                     text: str | None = None, pinned: bool | None = None, limit: int = 50) -> list[dict]:
        """List analyzed events, newest first.

        start/end: ISO 8601 local time (e.g. 2026-10-18T21:00) or unix epoch seconds.
        label: Frigate label (person, car, package). rule_id/vehicle_id: see describe().
        text: substring match on the summary and raw analysis.
        """
        where, params = filters(start, end, camera, rule_id, label, vehicle_id, text, pinned)
        sql = f"SELECT {EVENT_COLUMNS} FROM events e{where} ORDER BY e.started_at DESC LIMIT ?"
        with closing(ro()) as conn:
            return [row_dict(r) for r in conn.execute(sql, params + [min(limit, MAX_ROWS)])]


    @mcp.tool()
    def get_event(event_id: int, include_image: bool = True) -> list:
        """Full record for one event: analysis, findings, notifications, and the primary snapshot."""
        with closing(ro()) as conn:
            row = conn.execute("SELECT * FROM events WHERE id = ?", (event_id,)).fetchone()
            if row is None:
                return [f"event {event_id} not found"]
            event = row_dict(row)
            event["findings"] = [dict(r) for r in conn.execute(
                "SELECT rule_id, severity, detail FROM findings WHERE event_id = ?", (event_id,))]
            event["notifications"] = [dict(r) for r in conn.execute(
                "SELECT channel, status, error, sent_at FROM notifications WHERE event_id = ?", (event_id,))]
        out = [json.dumps(event, default=str)]
        if include_image and event["snapshots"] and not event["image_pruned"]:
            path = Path(event["snapshots"][0])
            if path.exists():
                out.append(Image(data=path.read_bytes(), format="jpeg"))
        return out


    @mcp.tool()
    def event_stats(group_by: str = "hour", start: str | None = None, end: str | None = None,
                    camera: str | None = None, rule_id: str | None = None, label: str | None = None,
                    vehicle_id: str | None = None) -> list[dict]:
        """Count events grouped by hour, weekday, day, camera, rule, purpose, vehicle or package_state.

        purpose and vehicle count individual people/vehicles; the rest count distinct events.
        """
        if group_by not in GROUPS:
            raise ValueError(f"group_by must be one of {sorted(GROUPS)}")
        expr, join = GROUPS[group_by]
        where, params = filters(start, end, camera, rule_id, label, vehicle_id, None, None)
        count = "count(*)" if group_by in ("purpose", "vehicle") else "count(DISTINCT e.id)"
        sql = (f"SELECT {expr} AS bucket, {count} AS count FROM events e {join}{where} "
               "GROUP BY bucket ORDER BY bucket")
        with closing(ro()) as conn:
            return [dict(r) for r in conn.execute(sql, params)]


    @mcp.tool()
    def run_sql(sql: str) -> list[dict]:
        """Run one read-only SELECT/WITH statement against the events database (max 500 rows).

        Tables: events, findings, notifications. See describe() for columns. JSON columns
        can be queried with json_each / json_extract.
        """
        statement = sql.strip().rstrip(";")
        if not statement.lower().startswith(("select", "with")) or ";" in statement:
            raise ValueError("only a single SELECT or WITH statement is allowed")
        with closing(ro()) as conn:
            conn.execute("PRAGMA query_only = ON")
            return [dict(r) for r in conn.execute(statement).fetchmany(MAX_ROWS)]


    def set_pin(event_id, pinned, reason):
        conn = sqlite3.connect(DB, timeout=10)
        with conn:
            cur = conn.execute("UPDATE events SET pinned = ?, pin_reason = ? WHERE id = ?",
                               (int(pinned), reason, event_id))
        conn.close()
        if cur.rowcount == 0:
            return f"event {event_id} not found"
        return f"event {event_id} {'pinned' if pinned else 'unpinned'}"


    @mcp.tool()
    def pin_event(event_id: int, reason: str) -> str:
        """Exempt an event (image, analysis and metadata) from retention pruning."""
        return set_pin(event_id, True, reason)


    @mcp.tool()
    def unpin_event(event_id: int) -> str:
        """Return an event to normal retention."""
        return set_pin(event_id, False, None)


    mcp.run(transport="streamable-http")
  ''
