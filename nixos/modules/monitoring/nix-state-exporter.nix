{ config, pkgs, ... }:

let
  textfileDir = "/var/lib/prometheus-node-exporter/textfile";

  nixStateExporter = pkgs.writeScript "nix-state-exporter.py" ''
    #!${pkgs.python3}/bin/python3
    import subprocess, json, os, sys

    PROM_FILE = "${textfileDir}/nix_state.prom"
    TMP_FILE = PROM_FILE + ".tmp"


    def prom_escape(s):
        return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


    # resolve selected commit fields from both comin JSON shapes
    def git_field(gen, key):
        git = ((gen or {}).get("source") or {}).get("git") or {}
        return git.get(key) or (gen or {}).get(key) or ""


    def fetched_commit(status):
        try:
            with open("/var/lib/comin/repository/refs/remotes/origin/main") as f:
                return f.read().strip()
        except OSError:
            return ((status.get("fetcher") or {}).get("repository_status") or {}).get("selected_commit_id", "")


    # fallback: newest done deployment from comin's local store
    def stored_deploy_gen():
        try:
            with open("/var/lib/comin/store.json") as f:
                deployments = json.load(f).get("deployments") or []
        except (OSError, ValueError):
            return {}
        done = [d for d in deployments if d.get("status") == "done"]
        latest = max(done, key=lambda d: d.get("ended_at") or "", default=None)
        return (latest or {}).get("generation") or {}


    lines = []
    comin_ok = False
    comin_err = ""

    # a daemon upgraded in place keeps its previous socket path
    def comin_status():
        base = ["comin", "status", "--json"]
        existing = [p for p in ("/run/comin-grpc.sock", "/var/lib/comin/grpc.sock") if os.path.exists(p)]
        result = None
        for path in existing:
            result = subprocess.run(base + ["--unix-socket-path", path], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                return result
        return result or subprocess.run(base, capture_output=True, text=True, timeout=10)


    # comin deployment state
    try:
        r = comin_status()
        if r.returncode != 0:
            stderr_lines = r.stderr.strip().splitlines()
            comin_err = (stderr_lines[-1] if stderr_lines else f"comin exited {r.returncode}")[:120]
        else:
            status = json.loads(r.stdout)

            gen = (status.get("builder") or {}).get("generation") or {}
            deploy = (status.get("deployer") or {}).get("deployment") or {}

            eval_status = gen.get("eval_status", "")
            build_status = gen.get("build_status", "")
            deploy_status = deploy.get("status", "")
            fetcher_commit_id = fetched_commit(status)
            commit = fetcher_commit_id[:8]
            commit_msg = git_field(gen, "selected_commit_msg").split("\n")[0][:72]

            deploy_gen = (deploy.get("generation") or {})
            if not git_field(deploy_gen, "selected_commit_id"):
                deploy_gen = stored_deploy_gen()
            deployed_commit_id = git_field(deploy_gen, "selected_commit_id")
            deployed_commit = deployed_commit_id[:8]
            deployed_msg = git_field(deploy_gen, "selected_commit_msg").split("\n")[0][:72]

            eval_val = 0 if eval_status == "failed" else 1
            build_val = 0 if build_status == "failed" else 1
            deploy_val = 0 if deploy_status == "failed" else 1

            try:
                running_system_path = os.readlink("/run/current-system")
            except OSError:
                running_system_path = ""
            built_out_path = gen.get("out_path", "")

            if eval_status == "failed" or build_status == "failed" or deploy_status == "failed":
                sync_val = 0
            elif not fetcher_commit_id or not deployed_commit_id:
                sync_val = 1
            elif fetcher_commit_id == deployed_commit_id:
                sync_val = 2
            elif built_out_path and built_out_path == running_system_path:
                # already-running store path counts as in-sync
                sync_val = 2
            else:
                sync_val = 1

            lines.append("# HELP comin_eval_success Whether the last comin eval succeeded")
            lines.append("# TYPE comin_eval_success gauge")
            lines.append(f"comin_eval_success {eval_val}")
            lines.append("# HELP comin_build_success Whether the last comin build succeeded")
            lines.append("# TYPE comin_build_success gauge")
            lines.append(f"comin_build_success {build_val}")
            lines.append("# HELP comin_deploy_success Whether the last comin deployment succeeded")
            lines.append("# TYPE comin_deploy_success gauge")
            lines.append(f"comin_deploy_success {deploy_val}")
            lines.append("# HELP comin_commit_info Currently tracked comin commit")
            lines.append("# TYPE comin_commit_info gauge")
            lines.append(
                f'comin_commit_info{{commit="{prom_escape(commit)}",'
                f'message="{prom_escape(commit_msg)}"}} 1'
            )
            lines.append("# HELP comin_deployed_commit_info Currently deployed comin commit")
            lines.append("# TYPE comin_deployed_commit_info gauge")
            lines.append(
                f'comin_deployed_commit_info{{commit="{prom_escape(deployed_commit)}",'
                f'message="{prom_escape(deployed_msg)}"}} 1'
            )
            lines.append("# HELP comin_sync_state Sync state (0=failed 1=pending 2=in-sync; a build identical to the running system counts as in-sync)")
            lines.append("# TYPE comin_sync_state gauge")
            lines.append(f"comin_sync_state {sync_val}")

            comin_ok = True
    except subprocess.TimeoutExpired:
        comin_err = "timeout after 10s"
    except Exception as e:
        comin_err = f"{type(e).__name__}: {e}"[:120]

    if not comin_ok:
        print(comin_err, file=sys.stderr)

    lines.append("# HELP comin_status_ok Whether comin status was read successfully")
    lines.append("# TYPE comin_status_ok gauge")
    lines.append(f"comin_status_ok {1 if comin_ok else 0}")
    lines.append("# HELP comin_status_error_info Error information when comin status failed")
    lines.append("# TYPE comin_status_error_info gauge")
    lines.append(
        f'comin_status_error_info{{error="{prom_escape(comin_err)}"}} {0 if comin_ok else 1}'
    )

    # NixOS system info
    try:
        with open("/run/current-system/nixos-version") as f:
            nixos_version = f.read().strip()
    except Exception:
        nixos_version = "unknown"

    try:
        with open("/proc/sys/kernel/osrelease") as f:
            kernel = f.read().strip()
    except Exception:
        kernel = "unknown"

    try:
        profile = os.readlink("/nix/var/nix/profiles/system")
        if profile.endswith("-link"):
            profile = profile[:-5]
        generation = int(profile.rsplit("-", 1)[-1])
    except Exception:
        generation = 0

    try:
        rebuild_ts = int(os.lstat("/run/current-system").st_mtime)
    except Exception:
        rebuild_ts = 0

    lines.append("# HELP nixos_rebuild_timestamp_seconds Mtime of /run/current-system")
    lines.append("# TYPE nixos_rebuild_timestamp_seconds gauge")
    lines.append(f"nixos_rebuild_timestamp_seconds {rebuild_ts}")
    lines.append("# HELP nixos_current_generation Current NixOS system profile generation")
    lines.append("# TYPE nixos_current_generation gauge")
    lines.append(f"nixos_current_generation {generation}")
    lines.append("# HELP nixos_info NixOS version and kernel")
    lines.append("# TYPE nixos_info gauge")
    lines.append(
        f'nixos_info{{version="{prom_escape(nixos_version)}",'
        f'kernel="{prom_escape(kernel)}"}} 1'
    )

    with open(TMP_FILE, "w") as f:
        f.write("\n".join(lines) + "\n")
    os.rename(TMP_FILE, PROM_FILE)
  '';
in
{
  systemd.services.nix-state-exporter = {
    description = "Export NixOS and comin state as Prometheus textfile metrics";
    path = [ config.services.comin.package ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${nixStateExporter}";
    };
  };

  systemd.timers.nix-state-exporter = {
    description = "Run nix-state-exporter periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "60s";
    };
  };
}
