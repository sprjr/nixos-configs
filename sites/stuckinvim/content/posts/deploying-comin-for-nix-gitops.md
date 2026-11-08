+++
title = "Deploying Comin for Nix GitOps"
date = 2026-11-07

[taxonomies]
topic = ["technical"]
tags = ["nix", "nixos", "comin", "ntfy"]
+++

Below is all you need (customized to preference, of course) to deploy [Comin](https://github.com/nlewo/comin) for handling NixOS gitops. It's worth noting that you should employ proper controls around your git repo that you build from, as this configuration doesn't do anything except deploy what it sees.

```nix
{ config, pkgs, ... }:

{
  services.comin = {
    enable = true;
    hostname = config.networking.hostName; # hostname of 'this' device
    remotes = [{
      name = "origin";
      url = "https://github.com/sprjr/nixos-configs.git";
      branches.main.name = "main";
      poller.period = 60; # seconds
    }];
  };
}
```

## | Visibility

Comin is a wonderful, if fairly straightforward and simple, way to manage gitops and build automation for Nix resources.

I found that visibility into the build state of my systems managed by comin were not very great by default. So, I wrote a nix-managed Python script that gets and pushes build states to a ntfy url/topic for me to get notification on build failures. It even incorporates a bit of sops, just for fun. I also created a Grafana dashboard, and created a widget for my hyprland + waybar config.

## | Grafana stack

Instead of putting the entire json file for the Grafana dashboard here, I'll just link the file:
[Grafana Nix State Dashboard](https://github.com/sprjr/nixos-configs/nixos/modules/monitoring/dashboards/nix-state.json)

## | Ntfy

```nix
{ config, pkgs, ... }:

let
  ntfyUrlFile = config.sops.secrets."monitoring/ntfy/comin-url".path;

  cominNotify = pkgs.writeScript "comin-notify.py" ''
    #!${pkgs.python3}/bin/python3
    import subprocess, json, os, sys

    hostname = "${config.networking.hostName}"
    with open("${ntfyUrlFile}") as f:
        ntfy_url = f.read().strip()
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

    # current comin nests commit metadata under source.git; released 0.14.0 and older keep it top-level
    def git_field(gen, key):
        git = ((gen or {}).get("source") or {}).get("git") or {}
        return git.get(key) or (gen or {}).get(key) or ""

    def fetched_commit(status):
        try:
            with open("/var/lib/comin/repository/refs/remotes/origin/main") as f:
                return f.read().strip()
        except OSError:
            fetcher = status.get("fetcher") or {}
            repo = fetcher.get("git_repository_status") or fetcher.get("repository_status") or {}
            return repo.get("selected_commit_id", "")

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

    status = get_status()
    if status is None:
        sys.exit(1)

    state = load_state()

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
```

## | Hyprland widget

Comin as a systemd service exposes a lot of great data, including the direct build logs (which I also pipe to a logging server) -- I found that grabbing the build state allowed me to write a custom widget in my hyprland config that informed me as to the build state of different hosts. This can all be found in [my home-manager settings](https://github.com/sprjr/nixos-configs/tree/main/home/modules/user-space/hyprland/control-center).
