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


    lines = []

    # comin deployment state
    try:
        r = subprocess.run(
            ["comin", "status", "--json"],
            capture_output=True, text=True, timeout=10,
        )
        if r.returncode == 0:
            status = json.loads(r.stdout)

            gen = (status.get("builder") or {}).get("generation") or {}
            deploy = (status.get("deployer") or {}).get("deployment") or {}
            fetcher = (status.get("fetcher") or {}).get("repository_status") or {}

            eval_status = gen.get("eval_status", "")
            build_status = gen.get("build_status", "")
            deploy_status = deploy.get("status", "")
            commit = fetcher.get("selected_commit_id", "")[:8]
            commit_msg = (gen.get("selected_commit_msg") or "").split("\n")[0][:72]

            eval_val = 0 if eval_status == "failed" else 1
            build_val = 0 if build_status == "failed" else 1
            deploy_val = 0 if deploy_status == "failed" else 1

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
    except Exception:
        pass

    # NixOS system info
    try:
        v = subprocess.run(["nixos-version"], capture_output=True, text=True, timeout=5)
        nixos_version = v.stdout.strip() if v.returncode == 0 else "unknown"
    except Exception:
        nixos_version = "unknown"

    try:
        k = subprocess.run(["uname", "-r"], capture_output=True, text=True, timeout=5)
        kernel = k.stdout.strip()
    except Exception:
        kernel = "unknown"

    try:
        profile = os.readlink("/nix/var/nix/profiles/system")
        generation = int(profile.rsplit("-", 1)[-1])
    except Exception:
        generation = 0

    try:
        rebuild_ts = int(os.path.getmtime("/run/current-system"))
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
