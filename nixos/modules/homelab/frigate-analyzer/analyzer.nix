{ pkgs }:

pkgs.writers.writePython3Bin "frigate-analyzer"
  {
    libraries = with pkgs.python3Packages; [
      paho-mqtt
      prometheus-client
      pyyaml
    ];
    doCheck = false;
  }
  ''
    import argparse
    import base64
    import itertools
    import json
    import logging
    import os
    import queue
    import re
    import sqlite3
    import threading
    import time
    import urllib.parse
    import urllib.request
    import uuid
    from datetime import datetime
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    from pathlib import Path

    import paho.mqtt.client as mqtt
    import yaml
    from prometheus_client import Counter, Gauge, Histogram, start_http_server

    log = logging.getLogger("frigate-analyzer")

    WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
    PURPOSES = ["delivery", "resident", "visitor", "solicitor", "service_worker", "loitering", "unknown"]
    SEVERITY_RANK = {"high": 3, "medium": 2, "low": 1}
    NTFY_PRIORITY = {"high": 4, "medium": 3, "low": 2}

    CONDITIONS = {
        "cameras", "source", "frigate_severity", "labels_any", "zones_any", "hours", "weekdays",
        "approaching_door", "purpose_in", "carrying_package", "vehicle_known", "vehicle_ids_any",
        "package_state",
    }
    VLM_CONDITIONS = {"approaching_door", "purpose_in", "carrying_package"}

    EVENTS = Counter("frigate_analyzer_events_total", "Stored events", ["camera", "source"])
    FINDINGS = Counter("frigate_analyzer_findings_total", "Rule matches", ["camera", "rule", "severity"])
    PEOPLE = Counter("frigate_analyzer_people_total", "People by apparent purpose", ["camera", "purpose"])
    VEHICLES = Counter("frigate_analyzer_vehicles_total", "Vehicles by resolved id", ["camera", "vehicle"])
    INFERENCE = Histogram(
        "frigate_analyzer_inference_seconds", "VLM inference latency", ["camera"],
        buckets=(1, 2, 5, 10, 20, 30, 60, 120),
    )
    INFERENCE_FAIL = Counter("frigate_analyzer_inference_failures_total", "VLM failures", ["camera"])
    NOTIFY = Counter("frigate_analyzer_notifications_total", "Notification attempts", ["channel", "status"])
    MQTT_UP = Gauge("frigate_analyzer_mqtt_connected", "MQTT connection state")
    PACKAGE = Gauge("frigate_analyzer_package_present", "Confirmed package presence", ["camera"])
    LAST_EVENT = Gauge("frigate_analyzer_last_event_timestamp_seconds", "Last stored event", ["camera"])
    QUEUE = Gauge("frigate_analyzer_queue_depth", "Pending analysis jobs")

    REVIEW_SCHEMA = {
        "type": "object",
        "properties": {
            "people": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "approaching_door": {"type": "boolean"},
                        "apparent_purpose": {"type": "string", "enum": PURPOSES},
                        "carrying_package": {"type": "boolean"},
                        "uniform_or_logo": {"type": "string"},
                        "description": {"type": "string"},
                    },
                    "required": ["approaching_door", "apparent_purpose", "carrying_package",
                                 "uniform_or_logo", "description"],
                },
            },
            "vehicles": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "color": {"type": "string"},
                        "make": {"type": "string"},
                        "body": {"type": "string"},
                        "matched_vehicle_id": {"type": "string"},
                        "confidence": {"type": "number"},
                    },
                    "required": ["color", "make", "body", "matched_vehicle_id", "confidence"],
                },
            },
            "packages_visible": {"type": "boolean"},
            "package_count": {"type": "integer"},
            "lighting": {"type": "string", "enum": ["day", "dusk", "night", "infrared"]},
            "summary": {"type": "string"},
        },
        "required": ["people", "vehicles", "packages_visible", "package_count", "lighting", "summary"],
    }

    SWEEP_SCHEMA = {
        "type": "object",
        "properties": {
            "packages_visible": {"type": "boolean"},
            "package_count": {"type": "integer"},
            "summary": {"type": "string"},
        },
        "required": ["packages_visible", "package_count", "summary"],
    }

    SYSTEM_PROMPT = (
        "You analyze still images from residential security cameras. "
        "Report only what is visible. Never guess the identity of a person. "
        "Answer strictly in the requested JSON format."
    )


    def credential(name):
        path = Path(os.environ.get("CREDENTIALS_DIRECTORY", "/nonexistent")) / name
        return path.read_text().strip() if path.exists() else None


    def http(url, data=None, headers=None, method=None, timeout=30):
        req = urllib.request.Request(url, data=data, headers=headers or {}, method=method)
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.read()


    def db_connect(path, schema_path):
        conn = sqlite3.connect(path, check_same_thread=False, timeout=10)
        conn.row_factory = sqlite3.Row
        conn.executescript(Path(schema_path).read_text())
        return conn


    def normalize_plate(plate):
        return re.sub(r"[^A-Z0-9]", "", str(plate).upper())


    def plate_near(a, b):
        # Exact match, or one OCR error on plates of 5+ characters
        if a == b:
            return True
        if abs(len(a) - len(b)) > 1 or min(len(a), len(b)) < 5:
            return False
        i = 0
        while i < min(len(a), len(b)) and a[i] == b[i]:
            i += 1
        return a[i + 1:] == b[i + 1:] or a[i:] == b[i + 1:] or a[i + 1:] == b[i:]


    def load_rules(text):
        doc = yaml.safe_load(text or "{}") or {}
        rules = []
        for rule in doc.get("rules", []):
            unknown = set(rule.get("when", {})) - CONDITIONS
            if unknown or "id" not in rule:
                log.error("rule %s invalid (unknown conditions %s); disabled", rule.get("id"), sorted(unknown))
                continue
            rule.setdefault("severity", "medium")
            rules.append(rule)
        return doc.get("vehicles", []), rules


    def check(key, want, facts):
        if key in VLM_CONDITIONS and facts["analysis"] is None:
            return False
        people = facts["people"]
        vehicles = facts["vehicles"]
        match key:
            case "cameras":
                return facts["camera"] in want
            case "source":
                return facts["source"] == want
            case "frigate_severity":
                return facts["frigate_severity"] in want
            case "labels_any":
                return bool(set(want) & set(facts["labels"]))
            case "zones_any":
                return bool(set(want) & set(facts["zones"]))
            case "hours":
                start, end = want
                hour = facts["hour"]
                return start <= hour < end if start <= end else (hour >= start or hour < end)
            case "weekdays":
                return facts["weekday"] in want
            case "approaching_door":
                return any(p.get("approaching_door") for p in people) == want
            case "purpose_in":
                return any(p.get("apparent_purpose") in want for p in people)
            case "carrying_package":
                return any(p.get("carrying_package") for p in people) == want
            case "vehicle_known":
                return any((v["vehicle_id"] is not None) == want for v in vehicles)
            case "vehicle_ids_any":
                return any(v["vehicle_id"] in want for v in vehicles)
            case "package_state":
                return facts["package_state"] == want
        return False


    def multipart(fields, files):
        boundary = uuid.uuid4().hex
        parts = []
        for key, value in fields.items():
            parts.append(
                f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode()
            )
        for key, (name, data, ctype) in files.items():
            head = (
                f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"; filename="{name}"\r\n'
                f"Content-Type: {ctype}\r\n\r\n"
            )
            parts.append(head.encode() + data + b"\r\n")
        parts.append(f"--{boundary}--\r\n".encode())
        return b"".join(parts), f"multipart/form-data; boundary={boundary}"


    class Analyzer:
        def __init__(self, cfg):
            self.cfg = cfg
            self.db = db_connect(cfg["db"], cfg["schema"])
            # (priority, seq, kind, payload); manual 0, review 1, sweep 2
            self.jobs = queue.PriorityQueue()
            self.seq = itertools.count()
            self.cooldowns = {}
            self.packages = {}
            self.secrets = {
                "mqtt": credential("mqtt-password"),
                "ntfy": credential("ntfy-url"),
                "telegram_token": credential("telegram-token"),
                "telegram_users": credential("telegram-users"),
                "ha_token": credential("ha-token"),
            }
            self.vehicles, self.rules = load_rules(credential("rules"))
            log.info("loaded %d rules, %d vehicles", len(self.rules), len(self.vehicles))
            for channel, key in (("ntfy", "ntfy"), ("telegram", "telegram_token"), ("ha_mobile", "ha_token")):
                if cfg["notify"][channel] and not self.secrets[key]:
                    log.error("notify channel %s enabled but its credential is missing", channel)

        # Frigate

        def frigate(self, path):
            return http(self.cfg["frigate_url"] + path, timeout=15)

        def save_snapshot(self, camera, ts, image):
            day = datetime.fromtimestamp(ts)
            folder = Path(self.cfg["snapshot_dir"]) / day.strftime("%Y/%m/%d")
            folder.mkdir(parents=True, exist_ok=True)
            path = folder / f"{camera}-{day.strftime('%H%M%S')}-{uuid.uuid4().hex[:8]}.jpg"
            path.write_bytes(image)
            return str(path)

        # Inference

        def analyze(self, camera, prompt, images, schema):
            body = json.dumps({
                "model": self.cfg["model"],
                "stream": False,
                "keep_alive": -1,
                "format": schema,
                "options": {"temperature": 0},
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": prompt,
                     "images": [base64.b64encode(i).decode() for i in images]},
                ],
            }).encode()
            error = None
            for attempt in range(2):
                started = time.monotonic()
                try:
                    raw = http(self.cfg["ollama_url"] + "/api/chat", body,
                               {"Content-Type": "application/json"}, timeout=180)
                    result = json.loads(json.loads(raw)["message"]["content"])
                    elapsed = time.monotonic() - started
                    INFERENCE.labels(camera).observe(elapsed)
                    return result, None, int(elapsed * 1000)
                except Exception as e:
                    error = f"{type(e).__name__}: {e}"
                    log.warning("inference attempt %d on %s failed: %s", attempt + 1, camera, error)
            INFERENCE_FAIL.labels(camera).inc()
            return None, error, None

        def review_prompt(self, camera, labels, zones):
            context = self.cfg["camera_context"].get(camera, "")
            lines = [f"Camera: {camera}. {context}"]
            if labels is not None:
                lines.append(
                    f"Frigate detected: {', '.join(labels) or 'nothing'}. Zones entered: {', '.join(zones) or 'none'}."
                )
            lines += [
                "approaching_door is true only if the person is walking toward or standing at the front door.",
                "apparent_purpose: delivery (carrier uniform, parcel, delivery vehicle), service_worker "
                "(utility or contractor), solicitor (flyers, clipboard, door to door), visitor, resident, "
                "loitering (lingering with no evident purpose), or unknown.",
                "For each vehicle set matched_vehicle_id to a known vehicle id below only if color, make "
                "and body all fit; otherwise set it to none.",
            ]
            if self.vehicles:
                lines.append("Known vehicles:")
                lines += ["- " + v["id"] + ": " + v.get("description", "") for v in self.vehicles]
            lines.append("summary: one or two plain sentences, no markdown.")
            return "\n".join(lines)

        def resolve_vehicles(self, plates, analysis):
            known = {v["id"] for v in self.vehicles}
            resolved = []
            matched = set()
            for plate in plates:
                vid = next(
                    (v["id"] for v in self.vehicles
                     for kp in v.get("plates", []) if plate_near(plate, normalize_plate(kp))),
                    None,
                )
                resolved.append({"vehicle_id": vid, "match_method": "plate", "plate": plate})
                if vid:
                    matched.add(vid)
            seen = (analysis or {}).get("vehicles", [])
            unknown = []
            for v in seen:
                vid = v.get("matched_vehicle_id")
                desc = " ".join(x for x in (v.get("color"), v.get("make"), v.get("body")) if x)
                if vid in known and v.get("confidence", 0) >= 0.7:
                    if vid not in matched:
                        resolved.append({"vehicle_id": vid, "match_method": "vlm", "description": desc})
                        matched.add(vid)
                else:
                    unknown.append({"vehicle_id": None, "match_method": "vlm", "description": desc})
            # Plate reads already account for that many vehicles in frame
            resolved += unknown[:max(0, len(seen) - len(plates))]
            return resolved

        # Jobs

        def handle_review(self, review):
            after = review["after"]
            data = after.get("data", {})
            review_id = after["id"]
            if self.db.execute("SELECT 1 FROM events WHERE review_id = ?", (review_id,)).fetchone():
                return
            camera = after["camera"]
            started = after.get("start_time") or time.time()
            labels = sorted({o.split("-")[0] for o in data.get("objects", [])})
            zones = sorted(set(data.get("zones", [])))

            detections = []
            for event_id in data.get("detections", [])[:10]:
                try:
                    detections.append(json.loads(self.frigate(f"/api/events/{event_id}")))
                except Exception as e:
                    log.warning("event %s lookup failed: %s", event_id, e)
            detections.sort(key=lambda d: (d.get("label") != "person",
                                           -((d.get("data") or {}).get("top_score") or d.get("top_score") or 0)))

            plates = []
            for d in detections:
                plate = (d.get("data") or {}).get("recognized_license_plate") or d.get("recognized_license_plate")
                if plate:
                    plates.append(normalize_plate(plate))

            images, paths = [], []
            for d in detections:
                if len(images) >= self.cfg["max_images"]:
                    break
                if not d.get("has_snapshot"):
                    continue
                try:
                    image = self.frigate(f"/api/events/{d['id']}/snapshot.jpg?bbox=0")
                except Exception as e:
                    log.warning("snapshot %s fetch failed: %s", d.get("id"), e)
                    continue
                images.append(image)
                paths.append(self.save_snapshot(camera, started, image))

            if images:
                analysis, error, ms = self.analyze(camera, self.review_prompt(camera, labels, zones),
                                                   images, REVIEW_SCHEMA)
            else:
                analysis, error, ms = None, "no snapshot available", None

            self.store(
                source="review", review_id=review_id, camera=camera, started=started,
                ended=after.get("end_time"), severity=after.get("severity"), labels=labels, zones=zones,
                plates=plates, paths=paths, images=images, analysis=analysis, error=error, ms=ms,
                package_state=None, detection_id=detections[0]["id"] if detections else None,
            )

        def handle_sweep(self, camera):
            try:
                image = self.frigate(f"/api/{camera}/latest.jpg?h=720")
            except Exception as e:
                log.warning("sweep fetch on %s failed: %s", camera, e)
                return
            context = self.cfg["camera_context"].get(camera, "")
            prompt = (
                f"Camera: {camera}. {context} "
                "Is any parcel, box, padded mailer or delivery bag left on the ground, porch or step? "
                "Ignore permanent items such as planters, furniture and mats. summary: one plain sentence."
            )
            analysis, error, ms = self.analyze(camera, prompt, [image], SWEEP_SCHEMA)
            if analysis is None:
                return

            seen = bool(analysis.get("packages_visible"))
            state = self.packages.setdefault(camera, {"confirmed": self.last_package_state(camera),
                                                      "candidate": None, "count": 0})
            if seen == state["confirmed"]:
                state["candidate"], state["count"] = None, 0
                return
            if seen == state["candidate"]:
                state["count"] += 1
            else:
                state["candidate"], state["count"] = seen, 1
            # Two consecutive agreeing sweeps before the state flips
            if state["count"] < 2:
                return
            previous = state["confirmed"]
            state["confirmed"], state["candidate"], state["count"] = seen, None, 0
            PACKAGE.labels(camera).set(int(seen))
            if previous is None:
                return

            now = time.time()
            self.store(
                source="sweep", review_id=None, camera=camera, started=now, ended=now, severity=None,
                labels=["package"] if seen else [], zones=[], plates=[],
                paths=[self.save_snapshot(camera, now, image)], images=[image], analysis=analysis,
                error=error, ms=ms, package_state="arrived" if seen else "removed", detection_id=None,
            )

        def handle_manual(self, request):
            camera, question = request["camera"], request.get("question")
            try:
                image = self.frigate(f"/api/{camera}/latest.jpg")
                prompt = self.review_prompt(camera, None, None)
                schema = REVIEW_SCHEMA
                if question:
                    prompt += "\nAlso answer this question in the answer field: " + question
                    schema = {
                        **REVIEW_SCHEMA,
                        "properties": {**REVIEW_SCHEMA["properties"], "answer": {"type": "string"}},
                        "required": REVIEW_SCHEMA["required"] + ["answer"],
                    }
                analysis, error, ms = self.analyze(camera, prompt, [image], schema)
                found = analysis or {}
                labels = [label for label, present in (
                    ("person", found.get("people")),
                    ("car", found.get("vehicles")),
                    ("package", found.get("packages_visible")),
                ) if present]
                now = time.time()
                path = self.save_snapshot(camera, now, image)
                event_id = self.store(
                    source="manual", review_id=None, camera=camera, started=now, ended=now, severity=None,
                    labels=labels, zones=[], plates=[], paths=[path], images=[image], analysis=analysis,
                    error=error, ms=ms, package_state=None, detection_id=None,
                    notify_mode="manual" if request.get("notify", True) else "none",
                )
                request["result"] = {
                    "event_id": event_id, "camera": camera, "summary": found.get("summary"),
                    "answer": found.get("answer"), "error": error, "snapshot": path, "analysis": analysis,
                }
            except Exception as e:
                request["result"] = {"camera": camera, "error": f"{type(e).__name__}: {e}"}
            finally:
                request["done"].set()

        def last_package_state(self, camera):
            row = self.db.execute(
                "SELECT package_state FROM events WHERE source = 'sweep' AND camera = ? "
                "ORDER BY started_at DESC LIMIT 1", (camera,)).fetchone()
            return None if row is None else row["package_state"] == "arrived"

        # Storage and rules

        def store(self, *, source, review_id, camera, started, ended, severity, labels, zones, plates,
                  paths, images, analysis, error, ms, package_state, detection_id, notify_mode="rules"):
            local = datetime.fromtimestamp(started)
            people = (analysis or {}).get("people", [])
            vehicles = self.resolve_vehicles(plates, analysis)
            facts = {
                "source": source, "camera": camera, "frigate_severity": severity, "labels": labels,
                "zones": zones, "hour": local.hour, "weekday": WEEKDAYS[local.weekday()],
                "people": people, "vehicles": vehicles, "package_state": package_state,
                "analysis": analysis,
            }
            summary = (analysis or {}).get("summary")

            cur = self.db.execute(
                "INSERT INTO events (review_id, source, camera, started_at, ended_at, local_time, local_hour, "
                "weekday, frigate_severity, labels, zones, plates, vehicles, package_state, snapshots, model, "
                "inference_ms, analysis, summary, error) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (review_id, source, camera, started, ended, local.isoformat(timespec="seconds"), local.hour,
                 facts["weekday"], severity, json.dumps(labels), json.dumps(zones), json.dumps(plates),
                 json.dumps(vehicles), package_state, json.dumps(paths), self.cfg["model"], ms,
                 json.dumps(analysis) if analysis is not None else None, summary, error),
            )
            event_id = cur.lastrowid
            matched = [] if source == "manual" else sorted(
                (r for r in self.rules if all(check(k, v, facts) for k, v in r.get("when", {}).items())),
                key=lambda r: -SEVERITY_RANK.get(r["severity"], 0))
            for rule in matched:
                self.db.execute(
                    "INSERT INTO findings (event_id, rule_id, severity, detail) VALUES (?, ?, ?, ?)",
                    (event_id, rule["id"], rule["severity"],
                     json.dumps({"description": rule.get("description"), "when": rule.get("when", {})})),
                )
                FINDINGS.labels(camera, rule["id"], rule["severity"]).inc()
            self.db.commit()

            EVENTS.labels(camera, source).inc()
            LAST_EVENT.labels(camera).set(started)
            for p in people:
                PEOPLE.labels(camera, p.get("apparent_purpose", "unknown")).inc()
            for v in vehicles:
                VEHICLES.labels(camera, v["vehicle_id"] or "unknown").inc()
            log.info("event %d %s/%s findings=%s error=%s", event_id, source, camera,
                     [r["id"] for r in matched], error)

            self.notify(event_id, facts, matched, summary, error, images[0] if images else None, detection_id,
                        notify_mode)
            return event_id

        # Notifications

        def cooled(self, rule, camera):
            key = (rule["id"], camera)
            now = time.time()
            if now - self.cooldowns.get(key, 0) < rule.get("cooldown", 0):
                return False
            self.cooldowns[key] = now
            return True

        def notify(self, event_id, facts, matched, summary, error, image, detection_id, notify_mode):
            if notify_mode == "none":
                return
            camera = facts["camera"]
            due = [r for r in matched if r.get("notify", True) and self.cooled(r, camera)]
            if notify_mode == "manual":
                title = f"Camera check - {camera}"
                severity = "low"
                answer = (facts["analysis"] or {}).get("answer")
                if answer:
                    summary = "\n".join(x for x in (answer, summary) if x)
            elif due:
                title = f"{due[0].get('description', due[0]['id'])} - {camera}"
                severity = due[0]["severity"]
            elif not self.rules and facts["frigate_severity"] == "alert":
                title = f"{', '.join(facts['labels']) or 'activity'} at {camera}"
                severity = "medium"
            elif error and facts["frigate_severity"] == "alert":
                title = f"Frigate alert at {camera} (analysis failed)"
                severity = "medium"
            else:
                return

            lines = [summary or f"Detected: {', '.join(facts['labels']) or 'unknown'}"]
            if due:
                lines.append("Rules: " + ", ".join(r["id"] for r in due))
            known = [v["vehicle_id"] for v in facts["vehicles"] if v["vehicle_id"]]
            if known:
                lines.append("Vehicles: " + ", ".join(known))
            lines.append(f"{facts['weekday']} {datetime.now().strftime('%H:%M')} | event {event_id}")
            if error:
                lines.append(f"Analysis error: {error}")
            body = "\n".join(lines)

            senders = {
                "ntfy": lambda: self.send_ntfy(title, body, image, severity),
                "telegram": lambda: self.send_telegram(title, body, image),
                "ha_mobile": lambda: self.send_ha(title, body, detection_id),
            }
            for channel, send in senders.items():
                if not self.cfg["notify"][channel]:
                    continue
                status, err = "ok", None
                try:
                    send()
                except Exception as e:
                    status, err = "error", f"{type(e).__name__}: {e}"
                    log.error("notify %s failed for event %d: %s", channel, event_id, err)
                NOTIFY.labels(channel, status).inc()
                self.db.execute(
                    "INSERT INTO notifications (event_id, channel, status, error, sent_at) VALUES (?, ?, ?, ?, ?)",
                    (event_id, channel, status, err, time.time()),
                )
            self.db.commit()

        def send_ntfy(self, title, body, image, severity):
            parts = urllib.parse.urlsplit(self.secrets["ntfy"])
            headers = {}
            if parts.username:
                password = urllib.parse.unquote(parts.password or "")
                auth = f"{urllib.parse.unquote(parts.username)}:{password}"
                headers["Authorization"] = "Basic " + base64.b64encode(auth.encode()).decode()
                parts = parts._replace(netloc=parts.hostname + (f":{parts.port}" if parts.port else ""))
            params = {"title": title, "priority": NTFY_PRIORITY.get(severity, 3)}
            if image:
                params |= {"message": body, "filename": "snapshot.jpg"}
                data, method = image, "PUT"
            else:
                data, method = body.encode(), "POST"
            url = parts.geturl()
            url += ("&" if "?" in url else "?") + urllib.parse.urlencode(params)
            http(url, data, headers, method=method, timeout=20)

        def send_telegram(self, title, body, image):
            token = self.secrets["telegram_token"]
            text = f"{title}\n{body}"
            for chat_id in [c.strip() for c in self.secrets["telegram_users"].split(",") if c.strip()]:
                if image:
                    data, ctype = multipart({"chat_id": chat_id, "caption": text[:1024]},
                                            {"photo": ("snapshot.jpg", image, "image/jpeg")})
                    http(f"https://api.telegram.org/bot{token}/sendPhoto", data, {"Content-Type": ctype}, timeout=30)
                else:
                    data = urllib.parse.urlencode({"chat_id": chat_id, "text": text[:4096]}).encode()
                    http(f"https://api.telegram.org/bot{token}/sendMessage", data, timeout=20)

        def send_ha(self, title, body, detection_id):
            payload = {"title": title, "message": body}
            if detection_id:
                payload["data"] = {"image": f"/api/frigate/notifications/{detection_id}/snapshot.jpg"}
            http(
                f"{self.cfg['ha_url']}/api/services/notify/{self.cfg['ha_service']}",
                json.dumps(payload).encode(),
                {"Authorization": f"Bearer {self.secrets['ha_token']}", "Content-Type": "application/json"},
                timeout=20,
            )

        # Runtime

        def on_connect(self, client, userdata, flags, reason_code, properties):
            if reason_code.is_failure:
                log.error("mqtt connect failed: %s", reason_code)
                return
            client.subscribe("frigate/reviews", qos=1)
            MQTT_UP.set(1)
            log.info("mqtt connected, subscribed to frigate/reviews")

        def on_disconnect(self, client, userdata, flags, reason_code, properties):
            MQTT_UP.set(0)
            log.warning("mqtt disconnected: %s", reason_code)

        def on_message(self, client, userdata, msg):
            try:
                review = json.loads(msg.payload)
            except ValueError:
                return
            if review.get("type") != "end":
                return
            self.submit(1, "review", review)

        def submit(self, priority, kind, payload):
            self.jobs.put((priority, next(self.seq), kind, payload))
            QUEUE.set(self.jobs.qsize())

        def sweep_loop(self):
            while True:
                for camera in self.cfg["sweep_cameras"]:
                    if self.jobs.qsize() < 5:
                        self.submit(2, "sweep", camera)
                time.sleep(self.cfg["sweep_interval"])

        def control_server(self):
            analyzer = self

            class Handler(BaseHTTPRequestHandler):
                def do_POST(self):
                    if self.path != "/assess":
                        self.send_error(404)
                        return
                    try:
                        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
                        camera = body["camera"]
                    except (ValueError, KeyError):
                        self.send_error(400, "expected JSON with a camera field")
                        return
                    request = {"camera": camera, "question": body.get("question"),
                               "notify": body.get("notify", True), "done": threading.Event()}
                    analyzer.submit(0, "manual", request)
                    request["done"].wait(300)
                    data = json.dumps(request.get("result", {"error": "timed out waiting for analysis"})).encode()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.send_header("Content-Length", str(len(data)))
                    self.end_headers()
                    self.wfile.write(data)

                def log_message(self, fmt, *args):
                    log.info("control: " + fmt, *args)

            ThreadingHTTPServer(("127.0.0.1", self.cfg["control_port"]), Handler).serve_forever()

        def run(self):
            start_http_server(self.cfg["metrics_port"])
            client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="frigate-analyzer")
            client.username_pw_set(self.cfg["mqtt_user"], self.secrets["mqtt"])
            client.on_connect = self.on_connect
            client.on_disconnect = self.on_disconnect
            client.on_message = self.on_message
            client.reconnect_delay_set(1, 60)
            client.connect_async(self.cfg["mqtt_host"], self.cfg["mqtt_port"], keepalive=60)
            client.loop_start()
            threading.Thread(target=self.sweep_loop, daemon=True).start()
            threading.Thread(target=self.control_server, daemon=True).start()
            handlers = {"manual": self.handle_manual, "review": self.handle_review, "sweep": self.handle_sweep}
            while True:
                _, _, kind, payload = self.jobs.get()
                QUEUE.set(self.jobs.qsize())
                try:
                    handlers[kind](payload)
                except Exception:
                    log.exception("%s job failed", kind)


    def prune(cfg, retention_days):
        conn = db_connect(cfg["db"], cfg["schema"])
        cutoff = time.time() - retention_days * 86400
        rows = conn.execute(
            "SELECT id, snapshots FROM events WHERE pinned = 0 AND image_pruned = 0 AND started_at < ?",
            (cutoff,)).fetchall()
        for row in rows:
            for path in json.loads(row["snapshots"]):
                Path(path).unlink(missing_ok=True)
            conn.execute("UPDATE events SET image_pruned = 1 WHERE id = ?", (row["id"],))
        conn.commit()
        for folder in sorted(Path(cfg["snapshot_dir"]).glob("*/*/*"), reverse=True):
            if folder.is_dir() and not any(folder.iterdir()):
                folder.rmdir()
        log.info("pruned images for %d events older than %d days", len(rows), retention_days)


    def main():
        parser = argparse.ArgumentParser()
        parser.add_argument("command", choices=["run", "prune", "assess"])
        parser.add_argument("camera", nargs="?", help="assess: camera name")
        parser.add_argument("--config", default="/etc/frigate-analyzer/config.json")
        parser.add_argument("--retention-days", type=int)
        parser.add_argument("--question", help="assess: question for the model to answer")
        parser.add_argument("--no-notify", action="store_true", help="assess: skip notifiers")
        args = parser.parse_args()
        logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
        cfg = json.loads(Path(args.config).read_text())
        if args.command == "assess":
            if not args.camera:
                parser.error("assess needs a camera")
            body = json.dumps({"camera": args.camera, "question": args.question, "notify": not args.no_notify})
            raw = http(f"http://127.0.0.1:{cfg['control_port']}/assess", body.encode(),
                       {"Content-Type": "application/json"}, method="POST", timeout=310)
            print(json.dumps(json.loads(raw), indent=2))
        elif args.command == "prune":
            days = args.retention_days if args.retention_days is not None else cfg["retention_days"]
            prune(cfg, days)
        else:
            Analyzer(cfg).run()


    if __name__ == "__main__":
        main()
  ''
