{
  config,
  pkgs,
  ...
}:

let
  botTokenFile = config.sops.secrets."hermes-agent/telegram-bot-token".path;
  allowedUsersFile = config.sops.secrets."hermes-agent/telegram-allowed-users".path;
  apiKeyFile = config.sops.secrets."hermes-agent/api-server-key".path;

  hermesRouter = pkgs.writeScript "hermes-router.py" ''
    #!${pkgs.python3}/bin/python3
    import json, sys, signal, urllib.request, urllib.parse, time

    with open("${botTokenFile}") as f:
        bot_token = f.read().strip()
    with open("${allowedUsersFile}") as f:
        allowed_users = set(uid.strip() for uid in f.read().strip().split(","))
    with open("${apiKeyFile}") as f:
        api_key = f.read().strip()

    HERMES_BASE = "http://127.0.0.1:8642"
    TELEGRAM_API = f"https://api.telegram.org/bot{bot_token}"

    ROUTES = {
        "!code": "/p/coder",
        "!research": "/p/researcher",
        "!home": "/p/home",
    }

    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    def get_updates(offset=None, timeout=30):
        params = {"timeout": timeout}
        if offset is not None:
            params["offset"] = offset
        url = f"{TELEGRAM_API}/getUpdates?" + urllib.parse.urlencode(params)
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=timeout + 10) as resp:
            return json.loads(resp.read())

    def send_message(chat_id, text):
        payload = urllib.parse.urlencode({
            "chat_id": chat_id,
            "text": text,
            "parse_mode": "Markdown",
        }).encode()
        req = urllib.request.Request(f"{TELEGRAM_API}/sendMessage", data=payload)
        try:
            urllib.request.urlopen(req, timeout=10)
        except Exception:
            payload = urllib.parse.urlencode({
                "chat_id": chat_id,
                "text": text,
            }).encode()
            req = urllib.request.Request(f"{TELEGRAM_API}/sendMessage", data=payload)
            urllib.request.urlopen(req, timeout=10)

    def query_hermes(message, profile_path, session_key):
        url = f"{HERMES_BASE}{profile_path}/v1/chat/completions"
        payload = json.dumps({
            "model": "hermes-agent",
            "messages": [
                {"role": "user", "content": message},
            ],
        }).encode()
        req = urllib.request.Request(
            url,
            data=payload,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "X-Hermes-Session-Key": session_key,
            },
        )
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = json.loads(resp.read())
            return data["choices"][0]["message"]["content"]

    offset = None
    while True:
        try:
            updates = get_updates(offset)
            for update in updates.get("result", []):
                offset = update["update_id"] + 1
                msg = update.get("message", {})
                chat_id = str(msg.get("chat", {}).get("id", ""))
                user_id = str(msg.get("from", {}).get("id", ""))
                text = (msg.get("text") or "").strip()

                if not text or not chat_id:
                    continue
                if user_id not in allowed_users:
                    continue

                profile_path = ""
                session_key = f"telegram:{chat_id}"
                for prefix, path in ROUTES.items():
                    if text.lower().startswith(prefix):
                        profile_path = path
                        text = text[len(prefix):].strip()
                        session_key = f"telegram:{chat_id}:{prefix.lstrip('!')}"
                        break

                try:
                    response = query_hermes(text, profile_path, session_key)
                    send_message(chat_id, response)
                except Exception as e:
                    send_message(chat_id, f"Error querying Hermes: {e}")
        except Exception:
            time.sleep(5)
  '';
in {
  systemd.services.hermes-router = {
    description = "Telegram router for Hermes Agent profiles";
    after = [
      "network-online.target"
      "podman-hermes-agent.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${hermesRouter}";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
