{ config, pkgs, ... }:

let
  # The topic path is the only thing gating publishes to ntfy, so the URL is read from the
  # sops-rendered file at runtime instead of being interpolated into a world-readable script.
  ntfyUrlFile = config.sops.secrets."monitoring/ntfy/comin-url".path;

  cominNotify = pkgs.writeScript "comin-notify.py" ''
    #!${pkgs.python3}/bin/python3
    import subprocess, json, os, sys, datetime

    hostname = "${config.networking.hostName}"
    with open("${ntfyUrlFile}") as f:
        ntfy_url = f.read().strip()
    state_file = "/var/lib/comin-notify/state.json"

    # a daemon upgraded in place keeps its previous socket path
    def comin_status():
        base = ["comin", "status", "--json"]
        existing = [p for p in ("/run/comin-grpc.sock", "/var/lib/comin/grpc.sock") if os.path.exists(p)]
        result = None
        for path in existing:
            result = subprocess.run(base + ["--unix-socket-path", path], capture_output=True, text=True)
            if result.returncode == 0:
                return result
        return result or subprocess.run(base, capture_output=True, text=True)

    def get_status():
        r = comin_status()
        if r.returncode != 0:
            print(f"comin status failed: {r.stderr}", file=sys.stderr)
            return None
        return json.loads(r.stdout)

    def publish(msg, priority=None, tags=None):
        args = ["ntfy", "publish"]
        if priority:
            args += ["--priority", priority]
        if tags:
            args += ["--tags", tags]
        args += [ntfy_url, msg]
        r = subprocess.run(args, capture_output=True, text=True)
        if r.returncode != 0:
            print(f"ntfy publish failed: {r.stderr}", file=sys.stderr)

    def load_state():
        if os.path.exists(state_file):
            with open(state_file) as f:
                return json.load(f)
        return {"last_commit_id": "", "last_failure_commit_id": ""}

    def save_state(state):
        with open(state_file, "w") as f:
            json.dump(state, f)

    # comin >= 0.14 nests the commit under source.git; older releases kept it top-level
    def git_field(gen, key):
        git = ((gen or {}).get("source") or {}).get("git") or {}
        return git.get(key) or (gen or {}).get(key) or ""

    def fetched_commit(status):
        try:
            with open("/var/lib/comin/repository/refs/remotes/origin/main") as f:
                return f.read().strip()
        except OSError:
            return ((status.get("fetcher") or {}).get("repository_status") or {}).get("selected_commit_id", "")

    def check_failure(status):
        gen = (status.get("builder") or {}).get("generation") or {}
        if gen.get("eval_status") == "failed":
            return git_field(gen, "selected_commit_id"), "eval failed: " + gen.get("eval_err", "").strip()
        if gen.get("build_status") == "failed":
            return git_field(gen, "selected_commit_id"), "build failed: " + gen.get("build_err", "").strip()
        dep = (status.get("deployer") or {}).get("deployment") or {}
        if dep.get("status") == "failed":
            return git_field(dep.get("generation"), "selected_commit_id"), "switch failed"
        return None, None

    def get_remotes(status):
        fetcher = status.get("fetcher") or {}
        repo = fetcher.get("git_repository_status") or fetcher.get("repository_status") or {}
        remotes = repo.get("remotes")
        if remotes is None and repo.get("error_msg"):
            return [{"name": "fetcher", "url": "", "fetch_error_msg": repo.get("error_msg", ""), "fetched_at": "", "fetched": False}]
        return remotes or []

    def get_journal_lines():
        try:
            r = subprocess.run(
                ["journalctl", "-u", "comin", "--since", "-15 min", "--no-pager", "-o", "cat"],
                capture_output=True, text=True, timeout=10,
            )
            if r.returncode != 0:
                return []
            seen = set()
            lines = []
            for line in r.stdout.splitlines():
                lower = line.lower()
                if any(k in lower for k in ("fail", "error", "timeout", "deadline", "resolve", "refused", "unreachable")):
                    stripped = line.strip()
                    if stripped and stripped not in seen:
                        seen.add(stripped)
                        lines.append(stripped)
            return ["  " + line[:300] for line in lines[-5:]]
        except Exception:
            return []

    status = get_status()
    if status is None:
        sys.exit(1)

    state = load_state()

    try:
        remotes = get_remotes(status)
        failing = [r for r in remotes if r.get("fetch_error_msg")]

        if failing and state.get("fetch_state", "ok") != "down":
            last_fetch = max(
                (r.get("fetched_at") or "" for r in remotes if r.get("fetched_at")),
                default=""
            )
            remote = failing[0]
            body = [
                hostname,
                f"{remote.get("name", "")} {remote.get("url", "")}",
                remote.get("fetch_error_msg", ""),
                f"last successful fetch: {last_fetch}",
            ] + get_journal_lines()
            publish("\n".join(body), priority="max", tags="rotating_light")
            state["fetch_state"] = "down"
            state["fetch_since"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        elif not failing and state.get("fetch_state", "ok") == "down":
            since = state.get("fetch_since", "")
            try:
                dt = datetime.datetime.fromisoformat(since)
                down_for = str(datetime.datetime.now(datetime.timezone.utc) - dt)
            except Exception:
                down_for = "unknown"
            publish(f"[{hostname}] comin can reach the remote again (was down for {down_for})", priority="low", tags="white_check_mark")
            state["fetch_state"] = "ok"
            state.pop("fetch_since", None)
    except Exception:
        import traceback
        traceback.print_exc()

    fetcher_commit = fetched_commit(status)
    if fetcher_commit and fetcher_commit != state["last_commit_id"]:
        gen = (status.get("builder") or {}).get("generation") or {}
        commit_msg = git_field(gen, "selected_commit_msg").split("\n")[0]
        publish(f"[{hostname}] new commit {fetcher_commit[:8]}: {commit_msg}", tags="arrow_up")
        state["last_commit_id"] = fetcher_commit

    fail_commit, fail_desc = check_failure(status)
    if fail_commit and fail_commit != state.get("last_failure_commit_id", ""):
        publish(f"[{hostname}] FAILED @ {fail_commit[:8]}: {fail_desc}", priority="high", tags="rotating_light")
        state["last_failure_commit_id"] = fail_commit

    save_state(state)
  '';
in {
  # Root-owned 0400; the unit below runs as root.
  sops.secrets."monitoring/ntfy/comin-url" = { };

  systemd.services.comin-notify = {
    description = "Check comin deployment status and send ntfy alerts";
    path = [ config.services.comin.package pkgs.ntfy-sh ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${cominNotify}";
      StateDirectory = "comin-notify";
    };
  };

  systemd.timers.comin-notify = {
    description = "Run comin-notify every 2 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
    };
  };
}
