# SQLite schema shared by the analyzer and the MCP server
''
  PRAGMA journal_mode = WAL;

  CREATE TABLE IF NOT EXISTS events (
    id               INTEGER PRIMARY KEY,
    review_id        TEXT UNIQUE,
    source           TEXT NOT NULL,
    camera           TEXT NOT NULL,
    started_at       REAL NOT NULL,
    ended_at         REAL,
    local_time       TEXT NOT NULL,
    local_hour       INTEGER NOT NULL,
    weekday          TEXT NOT NULL,
    frigate_severity TEXT,
    labels           TEXT NOT NULL DEFAULT '[]',
    zones            TEXT NOT NULL DEFAULT '[]',
    plates           TEXT NOT NULL DEFAULT '[]',
    vehicles         TEXT NOT NULL DEFAULT '[]',
    package_state    TEXT,
    snapshots        TEXT NOT NULL DEFAULT '[]',
    model            TEXT,
    inference_ms     INTEGER,
    analysis         TEXT,
    summary          TEXT,
    error            TEXT,
    pinned           INTEGER NOT NULL DEFAULT 0,
    pin_reason       TEXT,
    image_pruned     INTEGER NOT NULL DEFAULT 0
  );

  CREATE INDEX IF NOT EXISTS events_started_at ON events (started_at);
  CREATE INDEX IF NOT EXISTS events_camera ON events (camera, started_at);

  CREATE TABLE IF NOT EXISTS findings (
    id        INTEGER PRIMARY KEY,
    event_id  INTEGER NOT NULL REFERENCES events (id),
    rule_id   TEXT NOT NULL,
    severity  TEXT NOT NULL,
    detail    TEXT NOT NULL DEFAULT '{}'
  );

  CREATE INDEX IF NOT EXISTS findings_rule ON findings (rule_id);
  CREATE INDEX IF NOT EXISTS findings_event ON findings (event_id);

  CREATE TABLE IF NOT EXISTS notifications (
    id        INTEGER PRIMARY KEY,
    event_id  INTEGER NOT NULL REFERENCES events (id),
    channel   TEXT NOT NULL,
    status    TEXT NOT NULL,
    error     TEXT,
    sent_at   REAL NOT NULL
  );
''
