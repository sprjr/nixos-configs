# Ollama Cloud session/weekly usage for the waybar module (--waybar) and the AGS control center.
# `poll` (run by a user timer) is the only subcommand that hits the API; readers use the cache.
import argparse
import html
import json
import os
import statistics
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime

API = "https://ollama.com/api/balance"
KEY_ENV = "OLLAMA_USAGE_KEY_FILE"

# Assumed fixed window lengths; only the window-average projection depends on them
WINDOWS = {"session": 5 * 3600, "weekly": 7 * 86400}

RECENT_S = 1800
MIN_SPAN_S = 300
HISTORY_S = 86400
STALE_S = 180
TIGHT = 85
VERDICTS = ["ok", "tight", "over", "exhausted"]


def state_dir():
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    return os.path.join(base, "ollama-usage")


def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def save(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(obj, f)
    os.replace(tmp, path)


def parse_ts(value):
    return int(datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp())


def fetch(key):
    req = urllib.request.Request(API, headers={"Authorization": f"Bearer {key}", "User-Agent": "ollama-usage"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.load(resp)


def to_sample(resp, now):
    inc = resp["included"]
    sample = {"t": now}
    for name in WINDOWS:
        sample[f"{name}_used"] = round(100 - float(inc[name]["remaining_percent"]), 2)
        sample[f"{name}_reset"] = parse_ts(inc[name]["resets_at"])
    return sample


def describe(e):
    if isinstance(e, urllib.error.HTTPError):
        return f"HTTP {e.code} from {API}"
    if isinstance(e, urllib.error.URLError):
        return f"cannot reach {API}: {e.reason}"
    return f"unexpected response: {e!r}"


def recent(samples, name, reset, used, now):
    # Same reset time = same window; earlier windows would drag the slope negative
    pts = [(s["t"], s[f"{name}_used"]) for s in samples if s[f"{name}_reset"] == reset and s["t"] >= now - RECENT_S]
    if len(pts) < 2 or pts[-1][0] - pts[0][0] < MIN_SPAN_S:
        return None
    slope, _ = statistics.linear_regression([p[0] for p in pts], [p[1] for p in pts])
    rate = max(slope * 3600, 0.0)
    hours_left = max(reset - now, 0) / 3600
    exhausts_at = None
    if rate > 0 and used < 100:
        at = now + int((100 - used) / rate * 3600)
        exhausts_at = at if at < reset else None
    return {"rate_per_h": round(rate, 2), "projected": round(used + rate * hours_left, 1), "exhausts_at": exhausts_at}


def average(used, reset, window, now):
    elapsed = now - (reset - window)
    # Outside (0, window] means the fixed-window assumption doesn't hold for this reset
    if elapsed < 60 or elapsed > window:
        return None
    return {"projected": round(used * window / elapsed, 1)}


def verdict(used, rec, avg):
    if used >= 100:
        return "exhausted"
    projected = (rec or avg or {"projected": used})["projected"]
    if projected >= 100:
        return "over"
    return "tight" if projected >= TIGHT else "ok"


def compute(samples, now, error=None):
    if not samples:
        return {"ok": False, "error": error or "no data yet", "stale": True, "fetched_at": None, "session": None, "weekly": None}
    last = samples[-1]
    state = {"ok": error is None, "error": error, "stale": False, "fetched_at": last["t"]}
    for name, window in WINDOWS.items():
        used, reset = last[f"{name}_used"], last[f"{name}_reset"]
        rec = recent(samples, name, reset, used, now)
        avg = average(used, reset, window, now)
        state[name] = {
            "used": used,
            "resets_at": reset,
            "window_h": window // 3600,
            "recent": rec,
            "average": avg,
            "verdict": verdict(used, rec, avg),
        }
    return state


def poll():
    d = state_dir()
    history_path = os.path.join(d, "history.json")
    samples = load(history_path, [])
    now = int(time.time())
    error = None
    try:
        with open(os.environ[KEY_ENV]) as f:
            key = f.read().strip()
        samples.append(to_sample(fetch(key), now))
        samples = [s for s in samples if s["t"] >= now - HISTORY_S]
        save(history_path, samples)
    except (OSError, ValueError, KeyError, TypeError) as e:
        # URLError/HTTPError are OSError subclasses
        error = describe(e)
        print(error, file=sys.stderr)
    # Exit 0 on API errors: a failed unit would light up waybar's systemd-failed-units on every 429
    save(os.path.join(d, "latest.json"), compute(samples, now, error))


def read():
    state = load(os.path.join(state_dir(), "latest.json"), None) or compute([], 0)
    fetched = state.get("fetched_at")
    state["stale"] = fetched is None or time.time() - fetched > STALE_S
    return state


def countdown(seconds):
    seconds = max(int(seconds), 0)
    d, rem = divmod(seconds, 86400)
    h, m = rem // 3600, rem % 3600 // 60
    return f"{d}d{h}h" if d else f"{h}h{m:02d}m"


def window_lines(label, w, now):
    reset = datetime.fromtimestamp(w["resets_at"]).strftime("%a %H:%M")
    lines = [f"{label:<8} {w['used']:.1f}% used · resets {reset} (in {countdown(w['resets_at'] - now)})"]
    rec, avg = w["recent"], w["average"]
    if rec:
        line = f"  recent {rec['rate_per_h']:.1f}%/h → {rec['projected']:.0f}% at reset"
        if rec["exhausts_at"]:
            line += f" · limit in {countdown(rec['exhausts_at'] - now)}"
        lines.append(line)
    else:
        lines.append("  recent: collecting samples")
    if avg:
        lines.append(f"  window avg → {avg['projected']:.0f}% at reset")
    return lines


def waybar(state):
    now = time.time()
    s, w = state["session"], state["weekly"]
    if not s:
        return {"text": "󰚩 --", "class": ["unavailable"], "tooltip": html.escape(state["error"] or "no data")}
    worst = max(s["verdict"], w["verdict"], key=VERDICTS.index)
    lines = window_lines("Session", s, now) + window_lines("Weekly", w, now)
    if state["error"]:
        lines.append(f"Last poll failed: {state['error']}")
    if state["stale"]:
        lines.append(f"Data from {datetime.fromtimestamp(state['fetched_at']).strftime('%H:%M')}")
    return {
        "text": f"󰚩 S{s['used']:.0f}% W{w['used']:.0f}% · {countdown(s['resets_at'] - now)}",
        "class": [worst] + (["stale"] if state["stale"] else []),
        "tooltip": html.escape("\n".join(lines)),
    }


def main():
    parser = argparse.ArgumentParser(description="Report Ollama Cloud usage as JSON")
    parser.add_argument("command", nargs="?", choices=["poll"], help="fetch from the API and update the cache")
    parser.add_argument("--waybar", action="store_true", help="print a waybar custom-module object instead")
    args = parser.parse_args()
    if args.command == "poll":
        poll()
        return
    state = read()
    print(json.dumps(waybar(state) if args.waybar else state, ensure_ascii=False))


if __name__ == "__main__":
    main()
