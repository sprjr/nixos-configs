{ config, pkgs, lib, ... }:

let
  cfg = config.services.unit-failure-notify;

  unitFailureNotify = pkgs.writeScript "unit-failure-notify.py" ''
    #!${pkgs.python3}/bin/python3
    import json, os, re, subprocess, sys

    NTFY_URL_FILE = "${cfg.ntfyUrlFile}"
    STATE_FILE = "/var/lib/unit-failure-notify/state.json"
    HOSTNAME = "${config.networking.hostName}"
    IGNORED = [ ${builtins.concatStringsSep ", " (map builtins.toJSON cfg.ignoredUnits)} ]
    STUCK_POLLS = ${toString (builtins.ceil (cfg.stuckAfterMinutes / 2.0))}


    def ignored(name):
        return any(re.search(pattern, name) for pattern in IGNORED)


    def list_units(state):
        proc = subprocess.run(
            ["systemctl", "list-units", "--all", "--state=" + state,
             "--output=json", "--no-pager"],
            capture_output=True, text=True,
        )
        if proc.returncode != 0:
            print("systemctl failed: " + proc.stderr, file=sys.stderr)
            return None
        try:
            units = json.loads(proc.stdout or "[]")
        except json.JSONDecodeError as exc:
            print("unparseable systemctl output: " + str(exc), file=sys.stderr)
            return None
        found = {}
        for unit in units:
            name = unit.get("unit", "")
            if not name or unit.get("load") == "not-found" or ignored(name):
                continue
            found[name] = {
                "description": (unit.get("description") or "").strip(),
                "sub": unit.get("sub", ""),
            }
        return found


    def boot_id():
        with open("/proc/sys/kernel/random/boot_id") as fh:
            return fh.read().strip()


    def load_state():
        try:
            with open(STATE_FILE) as fh:
                state = json.load(fh)
        except (OSError, json.JSONDecodeError):
            state = {}
        if state.get("boot_id") != boot_id():
            state = {}
        state.setdefault("boot_id", boot_id())
        state.setdefault("notified", {})
        state.setdefault("watching", {})
        return state


    def save_state(state):
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        tmp = STATE_FILE + ".tmp"
        with open(tmp, "w") as fh:
            json.dump(state, fh)
        os.rename(tmp, STATE_FILE)


    def publish(title, body):
        try:
            with open(NTFY_URL_FILE) as fh:
                url = fh.read().strip()
        except OSError as exc:
            print("cannot read ntfy url: " + str(exc), file=sys.stderr)
            return False
        proc = subprocess.run(
            ["ntfy", "publish", "--title", title, "--priority", "high",
             "--tags", "rotating_light", url, body],
            capture_output=True, text=True,
        )
        if proc.returncode != 0:
            print("ntfy publish failed: " + proc.stderr, file=sys.stderr)
            return False
        return True


    failed = list_units("failed")
    if failed is None:
        sys.exit(1)
    activating = list_units("activating")
    if activating is None:
        sys.exit(1)

    looping = {
        name: info for name, info in activating.items()
        if info["sub"] == "auto-restart" and name.endswith(".service")
    }

    state = load_state()
    notified = state["notified"]
    watching = state["watching"]

    state["watching"] = {
        name: watching.get(name, 0) + 1 for name in looping
    }
    stuck = [name for name, count in state["watching"].items() if count >= STUCK_POLLS]

    unhealthy = {
        name: info["description"] or name for name, info in failed.items()
    }
    for name in stuck:
        unhealthy.setdefault(name, "restarting repeatedly, never starts")

    state["notified"] = {name: True for name in notified if name in unhealthy}

    new = sorted(name for name in unhealthy if name not in state["notified"])
    if new:
        if len(new) == 1:
            title = "[{}] {} unhealthy".format(HOSTNAME, new[0])
            body = "{} - {}".format(new[0], unhealthy[new[0]])
        else:
            title = "[{}] {} units unhealthy".format(HOSTNAME, len(new))
            body = "\n".join("{} - {}".format(n, unhealthy[n]) for n in new)
        if publish(title, body):
            for name in new:
                state["notified"][name] = True

    save_state(state)
  '';
in {
  options.services.unit-failure-notify = {
    enable = lib.mkEnableOption "ntfy notification when a systemd unit fails or cannot start";

    ntfyUrlFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the full ntfy publish URL, e.g. a sops secret.";
    };

    ignoredUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "^unit-failure-notify\\." ];
      description = "Regexes matched against unit names to exclude from alerts.";
    };

    stuckAfterMinutes = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = "Alert when a service stays in the activating state this long.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.unit-failure-notify = {
      description = "Check for failed or stuck systemd units and send ntfy alerts";
      path = [ config.systemd.package pkgs.ntfy-sh ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${unitFailureNotify}";
        StateDirectory = "unit-failure-notify";
      };
    };

    systemd.timers.unit-failure-notify = {
      description = "Run unit-failure-notify every 2 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "2min";
      };
    };
  };
}
