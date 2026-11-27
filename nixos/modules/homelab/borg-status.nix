{ config, pkgs, lib, ... }:

let
  port = 8095;
  stateDir = "/var/lib/borg-status";
  wwwDir = "${stateDir}/www";

  # Rough size of one full archive: Immich Server Stats, 2026-11-27 (2.79 TiB)
  expectedBytes = 3067589649612;

  woprKnownHosts = pkgs.writeText "wopr-known-hosts" ''
    wopr ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO14NPurz8+cyrYPcSR3Lw2/ldeSogC64G3MT7T7Qifx
  '';

  render = pkgs.writeScript "borg-status-render.py" ''
    #!${pkgs.python3}/bin/python3
    import html, json, os, re, sys, time

    RAW, ERR, STATE, OUT = sys.argv[1:5]
    EXPECTED = int(sys.argv[5])
    TARGETS = ["hetzner", "unraid"]
    PHASES = [
        ("Running consistency checks", "verifying"),
        ("Compacting", "compacting"),
        ("Pruning", "pruning"),
        ("Creating archive", "uploading"),
    ]


    def read(path):
        try:
            with open(path) as f:
                return f.read()
        except OSError:
            return ""


    def sections(text):
        out, cur = {}, None
        for line in text.splitlines():
            m = re.fullmatch(r"\[(.+)\]", line)
            if m:
                cur = m.group(1)
                out[cur] = []
            elif cur:
                out[cur].append(line)
        return out


    def props(lines):
        return dict(l.split("=", 1) for l in lines if "=" in l)


    def num(v):
        try:
            n = int(v)
        except (TypeError, ValueError):
            return None
        return None if n >= 2**63 else n


    def stamp(v):
        v = (v or "").strip()
        return int(v[1:].split(".")[0]) if v.startswith("@") else None


    def size(n):
        if n is None:
            return "n/a"
        for unit in ["B", "KiB", "MiB", "GiB", "TiB"]:
            if abs(n) < 1024 or unit == "TiB":
                return f"{n:.1f} {unit}" if unit != "B" else f"{n} B"
            n /= 1024


    def when(t, now):
        if t is None:
            return "n/a"
        local = time.strftime("%a %Y-%m-%d %H:%M", time.localtime(t))
        delta = int(t - now)
        ago = abs(delta)
        span = f"{ago // 86400}d {ago % 86400 // 3600}h" if ago >= 86400 else f"{ago // 3600}h {ago % 3600 // 60}m"
        return f"{local} ({'in ' + span if delta > 0 else span + ' ago'})"


    def duration(s):
        s = int(s)
        return f"{s // 86400}d {s % 86400 // 3600}h {s % 3600 // 60}m"


    def phase(log):
        for line in reversed(log):
            for needle, name in PHASES:
                if needle in line:
                    return name
        return "starting"


    raw = read(RAW)
    err = read(ERR).strip()
    sec = sections(raw)
    now = int(time.time())
    collected = num((sec.get("time") or [None])[0])
    try:
        prev = json.loads(read(STATE) or "{}")
    except json.JSONDecodeError:
        prev = {}
    state = {}
    cards = []

    for t in TARGETS:
        u = props(sec.get(f"unit {t}", []))
        tm = props(sec.get(f"timer {t}", []))
        log = sec.get(f"log {t}", [])
        active = u.get("ActiveState", "unknown")
        running = active in ("activating", "active", "deactivating")
        start = stamp(u.get("ExecMainStartTimestamp"))
        egress = num(u.get("IPEgressBytes"))
        ingress = num(u.get("IPIngressBytes"))
        ph = phase(log) if running else "idle"
        rows = []

        if running:
            moved = ingress if ph == "verifying" else egress
            p = prev.get(t, {})
            rate = None
            if moved is not None and p.get("moved") is not None and collected and p.get("start") == start and p.get("phase") == ph and collected > p.get("t", collected):
                inst = (moved - p["moved"]) / (collected - p["t"])
                rate = inst if p.get("rate") is None else 0.3 * inst + 0.7 * p["rate"]
            state[t] = {"t": collected, "start": start, "phase": ph, "moved": moved, "rate": rate}
            pct = min(100.0, 100.0 * moved / EXPECTED) if moved is not None else None
            eta = (EXPECTED - moved) / rate if rate and moved is not None and moved < EXPECTED else None
            rows += [
                ("Phase", ph),
                ("Running for", duration(collected - start) if start and collected else "n/a"),
                ("Uploaded", size(egress)),
                ("Downloaded", size(ingress)),
                ("Rate", f"{size(rate)}/s" if rate else "measuring"),
                ("ETA for this phase", duration(eta) if eta else "n/a"),
            ]
            bar = f'<progress max="100" value="{pct:.1f}"></progress> {pct:.1f}%' if pct is not None else "counters unavailable"
            badge, cls = "running", "run"
        else:
            result = u.get("Result", "unknown")
            ok = result == "success" and u.get("ExecMainStatus", "0") == "0"
            badge, cls = ("last run ok", "ok") if ok else (f"last run: {result}", "bad")
            if not start:
                badge, cls = "never run", "idle"
            bar = ""
            rows += [
                ("Last start", when(start, now)),
                ("Last finish", when(stamp(u.get("ExecMainExitTimestamp")), now)),
            ]

        rows += [
            ("Next scheduled", when(stamp(tm.get("NextElapseUSecRealtime")), now) if tm.get("UnitFileState") == "enabled" else "timer not enabled"),
        ]
        table = "".join(f"<tr><th>{html.escape(k)}</th><td>{html.escape(str(v))}</td></tr>" for k, v in rows)
        cards.append(f"""
          <section>
            <h2>{t} <span class="badge {cls}">{html.escape(badge)}</span></h2>
            <div class="bar">{bar}</div>
            <table>{table}</table>
            <details><summary>Last log lines</summary><pre>{html.escape(chr(10).join(log))}</pre></details>
          </section>""")

    disk = "\n".join(sec.get("disk", []))
    stale = not collected or now - collected > 900
    banner = ""
    if err:
        banner += f'<p class="warn">Collector error: {html.escape(err)}</p>'
    if stale:
        banner += '<p class="warn">Data is older than 15 minutes.</p>'

    page = f"""<!doctype html>
    <html lang="en"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="60">
    <title>wopr backups</title>
    <style>
      :root {{ --bg:#f6f6f4; --fg:#1d1d1b; --card:#fff; --muted:#6b6b66; --ok:#1f7a3a; --bad:#b3261e; --run:#1f5fa8; --warn:#8a5a00; }}
      @media (prefers-color-scheme: dark) {{ :root {{ --bg:#161615; --fg:#e8e8e4; --card:#21211f; --muted:#9a9a94; --ok:#5cc27a; --bad:#f2827a; --run:#7fb0ef; --warn:#e0b050; }} }}
      body {{ background:var(--bg); color:var(--fg); font:15px/1.45 system-ui,sans-serif; margin:0 auto; max-width:760px; padding:16px; }}
      section {{ background:var(--card); border-radius:8px; padding:12px 16px; margin:12px 0; }}
      h1 {{ font-size:20px; margin:4px 0; }} h2 {{ font-size:17px; margin:4px 0 8px; }}
      .badge {{ font-size:12px; padding:2px 8px; border-radius:10px; color:var(--card); vertical-align:middle; }}
      .ok {{ background:var(--ok); }} .bad {{ background:var(--bad); }} .run {{ background:var(--run); }} .idle {{ background:var(--muted); }}
      progress {{ width:70%; height:14px; vertical-align:middle; }}
      table {{ border-collapse:collapse; width:100%; }} th {{ text-align:left; color:var(--muted); font-weight:500; width:40%; padding:2px 0; }} td {{ padding:2px 0; }}
      pre {{ overflow-x:auto; font-size:12px; white-space:pre-wrap; word-break:break-all; }}
      .warn {{ color:var(--warn); }} .muted {{ color:var(--muted); font-size:13px; }}
    </style></head><body>
    <h1>wopr Immich backups</h1>
    <p class="muted">Collected {html.escape(when(collected, now))}. Progress is rough: bytes moved vs. {size(EXPECTED)} expected; counters start when IP accounting was enabled for the run.</p>
    {banner}
    {"".join(cards)}
    <section><h2>Disk</h2><pre>{html.escape(disk)}</pre></section>
    </body></html>
    """

    tmp = OUT + ".tmp"
    with open(tmp, "w") as f:
        f.write(page)
    os.chmod(tmp, 0o644)
    os.replace(tmp, OUT)
    with open(STATE + ".tmp", "w") as f:
        json.dump(state, f)
    os.replace(STATE + ".tmp", STATE)
  '';

  serve = pkgs.writeShellScript "borg-status-serve" ''
    ip4=$(${pkgs.iproute2}/bin/ip -4 -j addr show dev netbird0 | ${pkgs.jq}/bin/jq -r '.[0].addr_info[0].local // empty')
    if [ -z "$ip4" ]; then
      echo "netbird0 has no IPv4 address yet" >&2
      exit 1
    fi
    exec ${pkgs.python3}/bin/python3 -m http.server --bind "$ip4" --directory /srv ${toString port}
  '';
in
{
  users.users.borg-status = {
    isSystemUser = true;
    group = "borg-status";
    home = stateDir;
  };
  users.groups.borg-status = { };

  # Pull read-only status from wopr's borgstatus forced command, render a static page
  systemd.services.borg-status-collect = {
    description = "Collect wopr borgmatic status (read-only)";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.openssh pkgs.coreutils ];
    script = ''
      key=${stateDir}/ssh/id_ed25519
      mkdir -p ${stateDir}/ssh ${wwwDir}
      chmod 700 ${stateDir}/ssh
      chmod 755 ${wwwDir}
      [ -f "$key" ] || ssh-keygen -q -t ed25519 -N "" -C "borg-status@shikisha" -f "$key"

      if ssh -i "$key" -o BatchMode=yes -o ConnectTimeout=20 \
          -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${woprKnownHosts} \
          borgstatus@wopr > ${stateDir}/raw.tmp 2> ${stateDir}/err; then
        mv ${stateDir}/raw.tmp ${stateDir}/raw
        : > ${stateDir}/err
      fi

      ${render} ${stateDir}/raw ${stateDir}/err ${stateDir}/state.json ${wwwDir}/index.html ${toString expectedBytes}
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "borg-status";
      Group = "borg-status";
      StateDirectory = "borg-status";
      StateDirectoryMode = "0711";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.timers.borg-status-collect = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
    };
  };

  # Static page, bound to the NetBird overlay address only
  systemd.services.borg-status-web = {
    description = "wopr backup status page (NetBird only)";
    wantedBy = [ "multi-user.target" ];
    after = [ "netbird-default.service" "borg-status-collect.service" ];
    wants = [ "netbird-default.service" ];
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      ExecStart = serve;
      Restart = "always";
      RestartSec = 30;
      DynamicUser = true;
      BindReadOnlyPaths = [ "${wwwDir}:/srv" ];
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_NETLINK" "AF_UNIX" ];
    };
  };

  networking.firewall.interfaces.netbird0.allowedTCPPorts = [ port ];
}