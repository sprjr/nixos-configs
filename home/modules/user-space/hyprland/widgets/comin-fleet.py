# Comin state of the other fleet hosts for the control center, read from the Prometheus
# that scrapes nix-state-exporter.
# Prints one JSON object: {"ok", "total", "hosts": [{"host", "state", "commit"}], "detail"}.
# hosts lists only the hosts that are not in sync. state: failed | pending | offline
import argparse
import json
import socket
import urllib.parse
import urllib.request

URL = "http://shikisha:9090"
TIMEOUT = 3
# A host that reported comin state within this window is still a fleet member while down
WINDOW = "1d"

STATES = {0: "failed", 1: "pending", 2: "in-sync"}
ORDER = {"failed": 0, "pending": 1, "offline": 2}


def query(url, expr):
    qs = urllib.parse.urlencode({"query": expr})
    with urllib.request.urlopen(f"{url}/api/v1/query?{qs}", timeout=TIMEOUT) as r:
        body = json.load(r)
    if body.get("status") != "success":
        raise ValueError(body.get("error") or "query failed")
    return body["data"]["result"]


def host(sample):
    return sample["metric"].get("instance", "").rsplit(":", 1)[0]


def evaluate(url, me):
    sync = {host(s): int(float(s["value"][1])) for s in query(url, f"last_over_time(comin_sync_state[{WINDOW}])")}
    up = {host(s): s["value"][1] == "1" for s in query(url, 'up{job="node"}')}
    commits = {host(s): s["metric"].get("commit", "") for s in query(url, "comin_deployed_commit_info")}

    sync.pop(me, None)
    hosts = []
    for name, value in sync.items():
        state = STATES.get(value, "pending") if up.get(name) else "offline"
        if state != "in-sync":
            hosts.append({"host": name, "state": state, "commit": commits.get(name, "")[:7]})
    hosts.sort(key=lambda h: (ORDER[h["state"]], h["host"]))
    return {"ok": True, "total": len(sync), "hosts": hosts, "detail": ""}


def main():
    parser = argparse.ArgumentParser(description="Report fleet comin state as JSON")
    parser.add_argument("--url", default=URL)
    parser.add_argument("--self", dest="me", default=socket.gethostname().split(".")[0], help="host to leave out")
    args = parser.parse_args()
    try:
        out = evaluate(args.url.rstrip("/"), args.me)
    except (OSError, ValueError, KeyError, IndexError) as e:
        out = {"ok": False, "total": 0, "hosts": [], "detail": f"cannot query {args.url}: {e}"}
    print(json.dumps(out, ensure_ascii=False))


if __name__ == "__main__":
    main()
