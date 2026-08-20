{
  config,
  pkgs,
  ...
}:

let
  ntfyUrlFile = config.sops.secrets."monitoring/ntfy/frigate-events-url".path;
  mqttPasswordFile = config.sops.secrets."frigate/mqtt-password".path;

  frigateNotify = pkgs.writeScript "frigate-notify.py" ''
    #!${pkgs.python3}/bin/python3
    import subprocess, json, sys, signal

    with open("${ntfyUrlFile}") as f:
        ntfy_url = f.read().strip()
    with open("${mqttPasswordFile}") as f:
        mqtt_password = f.read().strip()

    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    proc = subprocess.Popen(
        ["mosquitto_sub", "-h", "shikisha", "-p", "1883",
         "-u", "frigate", "-P", mqtt_password,
         "-t", "frigate/events"],
        stdout=subprocess.PIPE, text=True
    )

    for line in proc.stdout:
        try:
            event = json.loads(line.strip())
            if event.get("type") != "new":
                continue
            after = event.get("after", {})
            label = after.get("label", "unknown")
            camera = after.get("camera", "unknown")
            score = after.get("top_score", 0)
            zones = ", ".join(after.get("current_zones", [])) or "no zone"

            title = f"{label} detected — {camera}"
            msg = f"Confidence: {score:.0%} | Zone: {zones}"

            subprocess.run(
                ["ntfy", "publish", "--title", title, ntfy_url, msg],
                capture_output=True, text=True
            )
        except (json.JSONDecodeError, KeyError):
            continue

    sys.exit(proc.wait())
  '';
in {
  sops.secrets."monitoring/ntfy/frigate-events-url" = { };

  systemd.services.frigate-notify = {
    description = "Forward Frigate detection events to ntfy";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.mosquitto pkgs.ntfy-sh ];
    serviceConfig = {
      ExecStart = "${frigateNotify}";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
