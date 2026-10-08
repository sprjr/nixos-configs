# Comin deployment state for the control center, derived from world-readable comin files.
# Prints one JSON object: {"state", "label", "commit", "time", "detail", "phase"}.
# state: in-sync | pending | in-progress | failed | unknown
# phase: eval | build | switch while in progress (time is then the phase start), else null
import argparse
import json
import os
import re
from datetime import datetime

STORE = "/var/lib/comin/store.json"
REPO = "/var/lib/comin/repository"
REF = "refs/remotes/origin/main"
CGROUP = "/sys/fs/cgroup/system.slice/comin.service/cgroup.procs"

EVAL_TERMINAL = {"evaluated", "failed"}
BUILD_TERMINAL = {"built", "failed"}
DEPLOY_TERMINAL = {"done", "failed"}


def result(state, label, commit="", time=None, detail="", phase=None):
    return {"state": state, "label": label, "commit": commit[:7], "time": time, "detail": detail, "phase": phase}


def git_info(gen):
    # comin >= 0.14 nests the commit under source.git; older releases kept it top-level
    git = ((gen or {}).get("source") or {}).get("git") or {}
    commit = git.get("selected_commit_id") or (gen or {}).get("selected_commit_id") or ""
    msg = git.get("selected_commit_msg") or (gen or {}).get("selected_commit_msg") or ""
    return commit, msg.split("\n")[0]


def parse_ts(value):
    if not value or value.startswith("0001-"):
        return None
    # Go emits nanoseconds; fromisoformat accepts at most microseconds
    value = re.sub(r"(\.\d{6})\d+", r"\1", value).replace("Z", "+00:00")
    try:
        return int(datetime.fromisoformat(value).timestamp())
    except ValueError:
        return None


def first_line(text):
    return (text or "").strip().split("\n")[0]


def read_ref(repo, ref):
    try:
        with open(os.path.join(repo, ref)) as f:
            return f.read().strip()
    except OSError:
        pass
    try:
        with open(os.path.join(repo, "packed-refs")) as f:
            for line in f:
                parts = line.split()
                if len(parts) == 2 and parts[1] == ref:
                    return parts[0]
    except OSError:
        pass
    return None


def cgroup_procs(path):
    try:
        with open(path) as f:
            return len(f.read().split())
    except OSError:
        return None


def evaluate(store_path, repo, ref, cgroup):
    procs = cgroup_procs(cgroup)
    if not procs:
        return result("unknown", "Unknown", detail="comin service is not running")

    try:
        with open(store_path) as f:
            store = json.load(f)
    except (OSError, ValueError) as e:
        return result("unknown", "Unknown", detail=f"cannot read comin store: {e}")

    remote = read_ref(repo, ref)
    if not remote:
        return result("unknown", "Unknown", detail=f"no fetched ref {ref}")

    generations = store.get("generations") or []
    deployments = store.get("deployments") or []
    suspended = (store.get("deployer") or {}).get("is_suspended", False)

    # Not-yet-started generations have no timestamp but are the newest
    gen = max(generations, key=lambda g: g.get("eval_started_at") or "~", default=None)
    dep = max(deployments, key=lambda d: d.get("created_at") or "", default=None)
    done = [d for d in deployments if d.get("status") == "done"]
    last_done = max(done, key=lambda d: d.get("ended_at") or "", default=None)

    if gen:
        commit, msg = git_info(gen)
        if gen.get("eval_status") == "failed":
            return result("failed", "Eval failed", commit, parse_ts(gen.get("eval_ended_at")), f"{first_line(gen.get('eval_err'))}\n{msg}")
        if gen.get("build_status") == "failed":
            return result("failed", "Build failed", commit, parse_ts(gen.get("build_ended_at")), f"{first_line(gen.get('build_err'))}\n{msg}")
    if dep and dep.get("status") == "failed":
        commit, msg = git_info(dep.get("generation"))
        return result("failed", "Switch failed", commit, parse_ts(dep.get("ended_at")), f"{first_line(dep.get('error_msg'))}\n{msg}")

    if gen:
        commit, msg = git_info(gen)
        deployed_uuids = {(d.get("generation") or {}).get("uuid") for d in deployments}
        if gen.get("eval_status") not in EVAL_TERMINAL:
            return result("in-progress", "Evaluating", commit, parse_ts(gen.get("eval_started_at")), msg, "eval")
        if gen.get("build_status") not in BUILD_TERMINAL:
            return result("in-progress", "Building", commit, parse_ts(gen.get("build_started_at")), msg, "build")
        if not suspended and gen.get("uuid") not in deployed_uuids:
            return result("in-progress", "Switching", commit, parse_ts(gen.get("build_ended_at")), msg, "switch")
    if dep and dep.get("status") not in DEPLOY_TERMINAL:
        commit, msg = git_info(dep.get("generation"))
        return result("in-progress", "Switching", commit, parse_ts(dep.get("started_at")), msg, "switch")
    if procs > 1:
        return result("in-progress", "In progress", remote, None, "comin has active child processes")

    if suspended:
        reason = (store.get("deployer") or {}).get("suspend_reason") or "deployer suspended"
        return result("pending", "Suspended", remote, None, reason)

    if not last_done:
        return result("pending", "Pending", remote, None, "no successful deployment recorded")
    deployed, msg = git_info(last_done.get("generation"))
    when = parse_ts(last_done.get("ended_at"))
    if deployed != remote:
        return result("pending", "Pending", remote, when, f"deployed {deployed[:7]}, remote at {remote[:7]}")
    return result("in-sync", "In sync", deployed, when, msg)


def main():
    parser = argparse.ArgumentParser(description="Report comin deployment state as JSON")
    parser.add_argument("--store", default=STORE)
    parser.add_argument("--repo", default=REPO)
    parser.add_argument("--ref", default=REF)
    parser.add_argument("--cgroup", default=CGROUP)
    args = parser.parse_args()
    print(json.dumps(evaluate(args.store, args.repo, args.ref, args.cgroup), ensure_ascii=False))


if __name__ == "__main__":
    main()
