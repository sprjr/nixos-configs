{
  config,
  pkgs,
  ...
}:

let
  mqttPasswordFile = config.sops.secrets."mosquitto/hermes-password".path;
  botTokenFile = config.sops.secrets."hermes-agent/telegram-bot-token".path;
  allowedUsersFile = config.sops.secrets."hermes-agent/telegram-allowed-users".path;
  haTokenFile = config.sops.secrets.ha_token.path;

  frigateHermes = pkgs.writeScript "frigate-hermes.py" ''
    #!${pkgs.python3}/bin/python3
    import subprocess, json, sys, signal, urllib.request, urllib.parse

    with open("${mqttPasswordFile}") as f:
        mqtt_password = f.read().strip()
    with open("${botTokenFile}") as f:
        bot_token = f.read().strip()
    with open("${allowedUsersFile}") as f:
        chat_ids = [uid.strip() for uid in f.read().strip().split(",")]
    with open("${haTokenFile}") as f:
        ha_token = f.read().strip()

    OLLAMA_API = "http://127.0.0.1:11434/api/chat"
    # Frigate's unauthenticated nginx web API (bound to localhost by the frigate module)
    FRIGATE_API = "http://127.0.0.1:5000"
    # Moondream: tiny purpose-built vision model — handles image analysis & summary
    MOONDREAM_MODEL = "moondream:1.8b"
    TELEGRAM_API = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    HA_NOTIFY_URL = "http://shikisha:8123/api/services/notify/mobile_app_pixel_8"

    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    def moondream_summarize(event_text, event_id=None):
        """Analyze a Frigate event with moondream.
        If a snapshot id is given, fetch the frame from Frigate and have
        moondream describe it. Then ask moondream to summarize. Returns a
        summary string, or None if inference fails."""
        import base64 as _b64

        description = ""
        if event_id:
            img_url = f"{FRIGATE_API}/api/events/{event_id}/snapshot.jpg"
            try:
                req = urllib.request.Request(img_url)
                with urllib.request.urlopen(req, timeout=15) as resp:
                    img_data = resp.read()
                img_b64 = _b64.b64encode(img_data).decode()
            except Exception:
                img_b64 = None
            if img_b64:
                # Moondream has a 2K context window; describe the frame first.
                try:
                    describe_payload = json.dumps({
                        "model": MOONDREAM_MODEL,
                        "messages": [{
                            "role": "user",
                            "content": ("Describe this camera frame concisely: people, "
                                        "vehicles, packages, or anything unusual."),
                            "images": ["data:image/jpeg;base64," + img_b64],
                        }],
                        "stream": False,
                        "keep_alive": -1,
                    }).encode()
                    req = urllib.request.Request(
                        OLLAMA_API, data=describe_payload,
                        headers={"Content-Type": "application/json"},
                    )
                    with urllib.request.urlopen(req, timeout=60) as resp:
                        data = json.loads(resp.read())
                        description = data["message"]["content"].strip()
                except Exception:
                    description = ""

        summary_prompt = (
            f"Summarize this Frigate NVR detection event for a home security alert. "
            f"Include camera, detection type, confidence, and zone. "
            f"Keep routine detections (known persons, pets) brief; give detailed "
            f"analysis for anything unusual.\n\n{event_text}"
        )
        if description:
            summary_prompt += f"\n\nThe camera frame shows: {description}"

        payload = json.dumps({
            "model": MOONDREAM_MODEL,
            "messages": [{"role": "user", "content": summary_prompt}],
            "stream": False,
            "keep_alive": -1,
        }).encode()
        req = urllib.request.Request(
            OLLAMA_API, data=payload,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read())
                return data["message"]["content"]
        except Exception:
            return None

    def send_telegram(text, chat_id):
        payload = urllib.parse.urlencode({
            "chat_id": chat_id,
            "text": text,
            "parse_mode": "Markdown",
        }).encode()
        req = urllib.request.Request(TELEGRAM_API, data=payload)
        try:
            urllib.request.urlopen(req, timeout=10)
        except Exception:
            pass

    def send_ha_notification(title, message, event_id=None):
        notification = {"title": title, "message": message}
        if event_id:
            notification["data"] = {
                "image": f"/api/frigate/notifications/{event_id}/snapshot.jpg",
            }
        payload = json.dumps(notification).encode()
        req = urllib.request.Request(
            HA_NOTIFY_URL,
            data=payload,
            headers={
                "Authorization": f"Bearer {ha_token}",
                "Content-Type": "application/json",
            },
        )
        try:
            urllib.request.urlopen(req, timeout=10)
        except Exception:
            pass

    proc = subprocess.Popen(
        ["mosquitto_sub", "-h", "shikisha", "-p", "1883",
         "-u", "hermes", "-P", mqtt_password,
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

            event_text = (
                f"Frigate detection event:\n"
                f"Camera: {camera}\n"
                f"Detected: {label}\n"
                f"Confidence: {score:.0%}\n"
                f"Zone: {zones}"
            )

            event_id = after.get("id") if after.get("has_snapshot") else None

            # Moondream analyzes the frame (if a snapshot exists) and summarizes.
            summary = moondream_summarize(event_text, event_id)
            message = summary if summary else event_text

            title = f"{label} detected — {camera}"
            send_ha_notification(title, message, event_id)

            for chat_id in chat_ids:
                send_telegram(message, chat_id)
        except (json.JSONDecodeError, KeyError):
            continue

    sys.exit(proc.wait())
  '';
in {
  sops.secrets."mosquitto/hermes-password" = { };

  systemd.services.frigate-hermes = {
    description = "Forward Frigate events through Ollama to Telegram and HA";
    after = [
      "network-online.target"
      "ollama.service"
      "sops-nix.service"
    ];
    wants = [ "network-online.target" "sops-nix.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.mosquitto ];
    serviceConfig = {
      ExecStart = "${frigateHermes}";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
