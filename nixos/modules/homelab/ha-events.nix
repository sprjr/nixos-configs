{
  config,
  pkgs,
  ...
}:

let
  webhookSecretFile = config.sops.secrets."ha-events/webhook-secret".path;
  botTokenFile = config.sops.secrets."hermes-agent/telegram-bot-token".path;
  allowedUsersFile = config.sops.secrets."hermes-agent/telegram-allowed-users".path;
  cloudApiKeyFile = config.sops.secrets."hermes-agent/cloud-api-key".path;

  haEvents = pkgs.writeScript "ha-events.py" ''
    #!${pkgs.python3}/bin/python3
    import json, sys, signal, time, threading
    import urllib.request, urllib.parse
    from http.server import HTTPServer, BaseHTTPRequestHandler

    with open("${webhookSecretFile}") as f:
        WEBHOOK_SECRET = f.read().strip()
    with open("${botTokenFile}") as f:
        bot_token = f.read().strip()
    with open("${allowedUsersFile}") as f:
        chat_ids = [uid.strip() for uid in f.read().strip().split(",")]
    with open("${cloudApiKeyFile}") as f:
        cloud_api_key = f.read().strip()

    # The main Hermes model (deepseek-v4-flash) is served from Ollama Cloud,
    # not from badgey's local 8GB AMD card — same OpenAI-compatible endpoint
    # and sops API key that hermes-agent.nix uses for the triage model.
    CLOUD_API = "https://ollama.com/v1/chat/completions"
    CLOUD_MODEL = "deepseek-v4-flash:0731"
    TELEGRAM_API = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    LISTEN_PORT = 8643
    RATE_LIMIT_SECONDS = 300

    SYSTEM_PROMPT = (
        "You are April, a home automation and security specialist. "
        "You receive Home Assistant state change events. "
        "Assess whether this event is noteworthy and summarize it concisely for Telegram. "
        "For security-relevant events (doors, locks, motion, alarms, leaks), "
        "always report with urgency context based on time of day. "
        "For routine state changes, keep it brief. "
        "If the event seems anomalous or concerning, explain why."
    )

    rate_limit_lock = threading.Lock()
    last_event_times = {}

    def is_rate_limited(entity_id):
        now = time.time()
        with rate_limit_lock:
            last = last_event_times.get(entity_id, 0)
            if now - last < RATE_LIMIT_SECONDS:
                return True
            last_event_times[entity_id] = now
            return False

    def cloud_summarize(event_text):
        payload = json.dumps({
            "model": CLOUD_MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": event_text},
            ],
            "stream": False,
        }).encode()
        req = urllib.request.Request(
            CLOUD_API,
            data=payload,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {cloud_api_key}",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read())
                return data["choices"][0]["message"]["content"]
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

    class WebhookHandler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            print(fmt % args, flush=True)

        def do_POST(self):
            if self.path != "/event":
                self.send_response(404)
                self.end_headers()
                return

            secret = self.headers.get("X-Webhook-Secret", "")
            if secret != WEBHOOK_SECRET:
                self.send_response(403)
                self.end_headers()
                return

            content_length = int(self.headers.get("Content-Length", 0))
            if content_length > 65536:
                self.send_response(413)
                self.end_headers()
                return

            body = self.rfile.read(content_length)
            self.send_response(202)
            self.end_headers()

            threading.Thread(
                target=self.process_event,
                args=(body,),
                daemon=True,
            ).start()

        def process_event(self, body):
            try:
                event = json.loads(body)
                entity_id = event.get("entity_id", "unknown")
                old_state = event.get("old_state", "unknown")
                new_state = event.get("new_state", "unknown")
                friendly_name = event.get("friendly_name", entity_id)
                timestamp = event.get("timestamp", "")

                if is_rate_limited(entity_id):
                    return

                event_text = (
                    f"Home Assistant state change:\n"
                    f"Entity: {friendly_name} ({entity_id})\n"
                    f"Changed: {old_state} -> {new_state}\n"
                    f"Time: {timestamp}"
                )

                summary = cloud_summarize(event_text)
                message = summary if summary else event_text

                for chat_id in chat_ids:
                    send_telegram(message, chat_id)
            except (json.JSONDecodeError, KeyError, IndexError) as e:
                print(f"Error processing event: {e}", flush=True)

        def do_GET(self):
            if self.path == "/health":
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"ok")
                return
            self.send_response(404)
            self.end_headers()

    def shutdown_handler(signum, frame):
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown_handler)
    signal.signal(signal.SIGINT, shutdown_handler)

    server = HTTPServer(("0.0.0.0", LISTEN_PORT), WebhookHandler)
    print(f"HA events webhook listening on port {LISTEN_PORT}", flush=True)
    server.serve_forever()
  '';
in {
  sops.secrets."ha-events/webhook-secret" = { };

  systemd.services.ha-events = {
    description = "Home Assistant event webhook to Hermes (deepseek-v4-flash)/Telegram";
    after = [
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [ "network-online.target" "sops-nix.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${haEvents}";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8643 ];
}
