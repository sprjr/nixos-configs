{ config, pkgs, ... }:

let
  ntfyUrl = "http://100.119.239.121:55455/rawliyosh-administration-notification-comin";

  cominNotify = pkgs.writeScript "comin-notify.py" ''
    #!${pkgs.python3}/bin/python3
    import subprocess, json, os, sys

    hostname = "${config.networking.hostName}"
    ntfy_url = "${ntfyUrl}"
    state_file = "/var/lib/comin-notify/state.json"

    def get_status():
        r = subprocess.run(["comin", "status", "--json"], capture_output=True, text=True)
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
        subprocess.run(args)

    def load_state():
        if os.path.exists(state_file):
            with open(state_file) as f:
                return json.load(f)
        return {"last_commit_id": "", "last_failure_commit_id": ""}

    def save_state(state):
        with open(state_file, "w") as f:
            json.dump(state, f)

    def check_failure(status):
        gen = (status.get("builder") or {}).get("generation") or {}
        if gen.get("eval_status") == "failed":
            return gen.get("selected_commit_id", ""), "eval failed: " + gen.get("eval_err", "").strip()
        if gen.get("build_status") == "failed":
            return gen.get("selected_commit_id", ""), "build failed: " + gen.get("build_err", "").strip()
        dep = (status.get("deployer") or {}).get("deployment") or {}
        if dep.get("status") == "failed":
            commit_id = (dep.get("generation") or {}).get("selected_commit_id", "")
            return commit_id, "switch failed"
        return None, None

    status = get_status()
    if status is None:
        sys.exit(1)

    state = load_state()

    fetcher_commit = ((status.get("fetcher") or {}).get("repository_status") or {}).get("selected_commit_id", "")
    if fetcher_commit and fetcher_commit != state["last_commit_id"]:
        gen = (status.get("builder") or {}).get("generation") or {}
        commit_msg = (gen.get("selected_commit_msg") or "").split("\n")[0]
        publish(f"[{hostname}] new commit {fetcher_commit[:8]}: {commit_msg}", tags="arrow_up")
        state["last_commit_id"] = fetcher_commit

    fail_commit, fail_desc = check_failure(status)
    if fail_commit and fail_commit != state.get("last_failure_commit_id", ""):
        publish(f"[{hostname}] FAILED @ {fail_commit[:8]}: {fail_desc}", priority="high", tags="rotating_light")
        state["last_failure_commit_id"] = fail_commit

    save_state(state)
  '';
in {
  systemd.services.comin-notify = {
    description = "Check comin deployment status and send ntfy alerts";
    path = [ config.services.comin.package ];
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
