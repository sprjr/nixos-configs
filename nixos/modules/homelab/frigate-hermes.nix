{
  config,
  pkgs,
  ...
}:

let
  mqttPasswordFile = config.sops.secrets."mosquitto/hermes-password".path;
  botTokenFile = config.sops.secrets."hermes-agent/telegram-bot-token".path;
  allowedUsersFile = config.sops.secrets."hermes-agent/telegram-allowed-users".path;

  frigateHermes = pkgs.writeScript "frigate-hermes.py" ''
    #!${pkgs.python3}/bin/python3
    import subprocess, json, sys, signal, urllib.request, urllib.parse

    with open("${mqttPasswordFile}") as f:
        mqtt_password = f.read().strip()
    with open("${botTokenFile}") as f:
        bot_token = f.read().strip()
    with open("${allowedUsersFile}") as f:
        chat_ids = [uid.strip() for uid in f.read().strip().split(",")]

    OLLAMA_API = "http://127.0.0.1:11434/api/chat"
    OLLAMA_MODEL = "qwen3.5:4b"
    TELEGRAM_API = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    SYSTEM_PROMPT = (
        "You are April, a home automation and security specialist. "
        "Summarize this Frigate NVR detection event concisely for Telegram. "
        "Include camera name, detection type, confidence, and zone. "
        "For routine detections (known persons, pets), keep summaries brief. "
        "For unusual detections, provide detailed analysis. "
        "Note patterns across recent events if context is available."
    )

    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    def ollama_summarize(event_text):
        payload = json.dumps({
            "model": OLLAMA_MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": event_text},
            ],
            "stream": False,
            "keep_alive": -1,
        }).encode()
        req = urllib.request.Request(
            OLLAMA_API,
            data=payload,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read())
                return data["message"]["content"]
        except Exception as e:
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

            summary = ollama_summarize(event_text)
            message = summary if summary else event_text

            for chat_id in chat_ids:
                send_telegram(message, chat_id)
        except (json.JSONDecodeError, KeyError):
            continue

    sys.exit(proc.wait())
  '';
in {
  sops.secrets."mosquitto/hermes-password" = { };

  systemd.services.frigate-hermes = {
    description = "Forward Frigate events through Ollama to Telegram";
    after = [
      "network-online.target"
      "ollama.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.mosquitto ];
    serviceConfig = {
      ExecStart = "${frigateHermes}";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
