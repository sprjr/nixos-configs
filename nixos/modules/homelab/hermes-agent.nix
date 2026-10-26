{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Cloud API base URLs — change cloudBase to switch all profiles at once
  # Ollama Cloud: "https://ollama.com/v1"
  # OpenCode Go:  "https://opencode.ai/zen/go/v1"
  cloudBase = "https://ollama.com/v1";

  mkModelBlock =
    {
      model,
      base_url ? cloudBase,
      context_length ? 131072,
      api_key ? false,
    }:
    let
      keyLine = if api_key then "\n  api_key: \${OPENAI_API_KEY}" else "";
    in
    ''
      model:
        default: ${model}
        provider: custom
        base_url: ${base_url}
        context_length: ${toString context_length}${keyLine}
    '';

  # Same toolset list on every platform the profile is reachable from
  mkToolsets =
    toolsets:
    let
      list = "[${lib.concatStringsSep ", " toolsets}]";
    in
    ''
      platform_toolsets:
        api_server: ${list}
        telegram: ${list}
        cli: ${list}
    '';

  triageToolsets = mkToolsets [
    "terminal"
    "file"
    "web"
    "code_execution"
    "vision"
    "skills"
    "todo"
    "memory"
    "session_search"
    "delegation"
    "cronjob"
    "frigate"
  ];
  coderToolsets = mkToolsets [
    "terminal"
    "file"
    "web"
    "code_execution"
    "skills"
    "todo"
    "memory"
    "session_search"
    "delegation"
  ];
  researcherToolsets = mkToolsets [
    "web"
    "browser"
    "file"
    "code_execution"
    "skills"
    "todo"
    "memory"
    "session_search"
    "delegation"
  ];
  homeToolsets = mkToolsets [
    "terminal"
    "file"
    "vision"
    "skills"
    "todo"
    "memory"
    "session_search"
    "frigate"
  ];

  # Per-profile model assignments
  triageModel = mkModelBlock {
    model = "deepseek-v4.1-flash";
    api_key = true;
  };
  coderModel = mkModelBlock {
    model = "kimi-k2.7-code";
    api_key = true;
  };
  researcherModel = mkModelBlock {
    model = "glm-5.3";
    context_length = 1000000;
    api_key = true;
  };
  homeModel = mkModelBlock {
    model = "gemma4:31b";
    context_length = 128000;
    api_key = true;
  };

  localModel = mkModelBlock {
    model = "gemma3:4b";
    base_url = "http://host.containers.internal:11434/v1";
    context_length = 16384;
  };

  # frigate-analyzer MCP server, bound to the hermes-net gateway on the host
  frigateMcp = ''
    mcp_servers:
      frigate:
        url: http://10.89.0.1:8650/mcp
  '';

  hermesConfigYaml = pkgs.writeText "hermes-config.yaml" ''
    ${triageModel}
    ${frigateMcp}
    ${triageToolsets}
    delegation:
      max_iterations: 60
      max_concurrent_children: 3
      max_spawn_depth: 1
      subagent_auto_approve: false
    terminal:
      env: local
    dashboard:
      theme: mono
    memory:
      memory_enabled: true
      user_profile_enabled: true
    cron:
      preflight: true
      failure_nudge_threshold: 3
      allow_agent_scheduling: true
      wrap_response: true
      model: deepseek-v4.1-flash
      model_provider: custom
    platforms:
      telegram:
        allow_from:
          - "8689937825"
    skills:
      auto_load:
        - i-have-adhd
    onboarding:
      seen:
        busy_input_prompt: true
  '';

  coderConfigYaml = pkgs.writeText "hermes-coder-config.yaml" ''
    ${coderModel}
    ${coderToolsets}
    terminal:
      env: local
  '';

  researcherConfigYaml = pkgs.writeText "hermes-researcher-config.yaml" ''
    ${researcherModel}
    ${researcherToolsets}
  '';

  homeConfigYaml = pkgs.writeText "hermes-home-config.yaml" ''
    ${homeModel}
    ${frigateMcp}
    ${homeToolsets}
    terminal:
      env: local
  '';

  delegateScript = pkgs.writeText "hermes-delegate.py" ''
    #!/usr/bin/env python3
    import json, os, socket, subprocess, sys, time, urllib.error, urllib.request

    SCRIPT_PATH = os.path.realpath(os.path.abspath(__file__))
    SYNC_TIMEOUT_DEFAULT = 1800
    WORKER_TIMEOUT_DEFAULT = 0
    JOB_DIR_DEFAULT = "/opt/data/cache/delegate-jobs"
    LOCK_DIR_DEFAULT = "/opt/data/cache/delegate-locks"

    def _int_env(name, default):
        try:
            v = os.environ.get(name, str(default))
            return int(v) if v.strip() != "" else default
        except Exception:
            return default

    def _api_key():
        key = os.environ.get("API_SERVER_KEY", "")
        if not key:
            fail("API_SERVER_KEY not set")
        return key

    def _url(profile):
        return os.environ.get(
            "DELEGATE_URL", f"http://127.0.0.1:8642/p/{profile}/v1/chat/completions"
        )

    def _read_task(arg):
        return open(arg[1:]).read() if arg.startswith("@") else arg

    def fail(msg, code=1):
        print(f"DELEGATION_ERROR: {msg}")
        sys.exit(code)

    def _set_status(job_dir, status):
        tmp = os.path.join(job_dir, ".status.tmp")
        with open(tmp, "w") as f:
            f.write(status)
        os.replace(tmp, os.path.join(job_dir, "status"))

    def _acquire_profile_lock(profile, stderr=sys.stderr):
        try:
            import fcntl
            lock_dir = os.environ.get("DELEGATE_LOCK_DIR", LOCK_DIR_DEFAULT)
            os.makedirs(lock_dir, exist_ok=True)
            lock = open(os.path.join(lock_dir, f"{profile}.lock"), "a+")
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError:
                print(f"[waiting: another {profile} delegation holds the lock]", file=stderr)
                fcntl.flock(lock, fcntl.LOCK_EX)
            return lock
        except Exception as e:
            print(f"[lock unavailable: {e}]", file=stderr)
            return None

    def _http_post(profile, task, timeout, stderr=sys.stderr):
        api_key = _api_key()
        url = _url(profile)
        session_key = f"delegation:{int(time.time())}:{os.getpid()}"
        payload = json.dumps({
            "model": "hermes-agent",
            "messages": [{"role": "user", "content": task}],
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
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=timeout or None) as resp:
                data = json.loads(resp.read())
            content = data["choices"][0]["message"]["content"]
            print(f"[delegation completed in {time.time()-t0:.0f}s]", file=stderr)
            return content
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "replace")[:4096]
            raise RuntimeError(f"HTTP {e.code}: {body}")
        except Exception as e:
            raise RuntimeError(str(e))

    def do_sync(profile, task):
        lock = _acquire_profile_lock(profile)
        try:
            print(_http_post(profile, task, _int_env("DELEGATE_TIMEOUT", SYNC_TIMEOUT_DEFAULT)))
        except Exception as e:
            fail(e)
        finally:
            try:
                lock.close()
            except Exception:
                pass

    def _resolve_job_dir(token):
        if os.path.isdir(token):
            return token
        base = os.environ.get("DELEGATE_JOB_DIR", JOB_DIR_DEFAULT)
        path = os.path.join(base, token)
        if os.path.isdir(path):
            return path
        return None

    def _parse_meta(job_dir):
        try:
            with open(os.path.join(job_dir, "meta.json")) as f:
                return json.load(f)
        except Exception:
            return None

    def _read_status(job_dir):
        try:
            with open(os.path.join(job_dir, "status")) as f:
                return f.read().strip()
        except Exception:
            return "unknown"

    def _job_age(meta):
        try:
            return int(time.time() - meta.get("started_at_epoch", time.time()))
        except Exception:
            return 0

    def _profile(meta):
        try:
            return meta.get("profile", "")
        except Exception:
            return ""

    def _job_id(job_dir):
        return os.path.basename(os.path.normpath(job_dir))

    def do_worker(job_dir):
        meta = _parse_meta(job_dir)
        if not meta:
            fail(f"worker: cannot read meta.json in {job_dir}")
        profile = _profile(meta)
        if not profile:
            fail("worker: missing profile in meta.json")
        task = open(os.path.join(job_dir, "task.txt")).read()
        lock = _acquire_profile_lock(profile)
        try:
            timeout = _int_env("DELEGATE_WORKER_TIMEOUT", WORKER_TIMEOUT_DEFAULT)
            content = _http_post(profile, task, timeout)
            with open(os.path.join(job_dir, "result.txt"), "w") as f:
                f.write(content)
            _set_status(job_dir, "done")
        except Exception as e:
            with open(os.path.join(job_dir, "error.txt"), "w") as f:
                f.write(str(e))
            _set_status(job_dir, "error")
        finally:
            try:
                lock.close()
            except Exception:
                pass

    def do_async(profile, task):
        base = os.environ.get("DELEGATE_JOB_DIR", JOB_DIR_DEFAULT)
        os.makedirs(base, exist_ok=True)
        host = socket.gethostname()
        pid = os.getpid()
        now = time.time()
        stamp = time.strftime("%Y%m%dT%H%M%S", time.gmtime(now))
        job_id = f"{stamp}-{profile}-{pid}"
        job_dir = os.path.join(base, job_id)
        os.makedirs(job_dir, exist_ok=True)
        with open(os.path.join(job_dir, "task.txt"), "w") as f:
            f.write(task)
        meta = {
            "profile": profile,
            "started_at": time.strftime("%Y-%m-%dT%H:%M:%S+00:00", time.gmtime(now)),
            "started_at_epoch": now,
            "pid": pid,
            "host": host,
        }
        with open(os.path.join(job_dir, "meta.json"), "w") as f:
            json.dump(meta, f)
        _set_status(job_dir, "running")
        cmd = [sys.executable, SCRIPT_PATH, "--worker", job_dir]
        log_path = os.path.join(job_dir, "worker.log")
        with open(log_path, "w") as log:
            subprocess.Popen(
                cmd,
                start_new_session=True,
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=subprocess.STDOUT,
                cwd="/",
            )
        print(f"DELEGATION_JOB {job_dir}")

    def do_status(token):
        job_dir = _resolve_job_dir(token)
        if not job_dir:
            fail(f"unknown job: {token}")
        meta = _parse_meta(job_dir) or {}
        status = _read_status(job_dir)
        age = _job_age(meta)
        print(f"STATUS {status} {age}s {_profile(meta)}")

    def do_wait(token, limit=None):
        job_dir = _resolve_job_dir(token)
        if not job_dir:
            fail(f"unknown job: {token}")
        t0 = time.time()
        while True:
            status = _read_status(job_dir)
            if status == "done":
                print(open(os.path.join(job_dir, "result.txt")).read())
                return 0
            if status == "error":
                err = ""
                try:
                    err = open(os.path.join(job_dir, "error.txt")).read().strip()
                except Exception:
                    pass
                print(f"DELEGATION_ERROR: {err}" if err else "DELEGATION_ERROR: worker failed")
                return 1
            if limit is not None and time.time() - t0 >= limit:
                print("DELEGATION_ERROR: wait timeout", file=sys.stderr)
                return 2
            time.sleep(0.5)

    def do_jobs():
        base = os.environ.get("DELEGATE_JOB_DIR", JOB_DIR_DEFAULT)
        try:
            entries = os.listdir(base)
        except Exception:
            return
        job_dirs = []
        for e in entries:
            path = os.path.join(base, e)
            if os.path.isdir(path) and os.path.isfile(os.path.join(path, "meta.json")):
                job_dirs.append(path)
        job_dirs.sort(key=lambda p: os.path.basename(p), reverse=True)
        for path in job_dirs:
            meta = _parse_meta(path) or {}
            status = _read_status(path)
            age = _job_age(meta)
            task = ""
            try:
                task = open(os.path.join(path, "task.txt")).read()
            except Exception:
                pass
            preview = task.replace("\n", " ")[:60]
            print(f"{_job_id(path)} {status} {age}s {_profile(meta)} {preview}")

    def main():
        args = sys.argv[1:]
        if not args:
            print("Usage: delegate.py [--async|--status|--wait|--jobs] <profile> <task|@taskfile>")
            sys.exit(1)

        if args[0] == "--worker" and len(args) == 2:
            do_worker(args[1])
            return

        if args[0] == "--async":
            if len(args) < 3:
                fail("Usage: delegate.py --async <profile> <task|@taskfile>")
            profile = args[1]
            task = _read_task(" ".join(args[2:]))
            do_async(profile, task)
            return

        if args[0] == "--status":
            if len(args) != 2:
                fail("Usage: delegate.py --status <jobdir|id>")
            do_status(args[1])
            return

        if args[0] == "--wait":
            if len(args) < 2:
                fail("Usage: delegate.py --wait <jobdir|id> [seconds]")
            limit = None
            if len(args) >= 3:
                try:
                    limit = int(args[2])
                except Exception:
                    fail("seconds must be an integer")
            sys.exit(do_wait(args[1], limit))

        if args[0] == "--jobs":
            do_jobs()
            return

        if len(args) < 2:
            fail("Usage: delegate.py <profile> <task|@taskfile>")
        profile = args[0]
        task = _read_task(" ".join(args[1:]))
        do_sync(profile, task)

    if __name__ == "__main__":
        main()
  '';
in
{
  sops.secrets."hermes-agent/telegram-bot-token" = { };
  sops.secrets."hermes-agent/telegram-native-bot-token" = { };
  sops.secrets."hermes-agent/telegram-allowed-users" = { };
  sops.secrets."hermes-agent/dashboard-username" = { };
  sops.secrets."hermes-agent/dashboard-password" = { };
  sops.secrets."hermes-agent/api-server-key" = { };
  sops.secrets."hermes-agent/cloud-api-key" = { };
  sops.secrets."hermes-agent/forgejo-pat" = { };
  sops.secrets."hermes-agent/github-pat" = { };
  sops.secrets."hermes-agent/windows-mcp-token" = { };
  sops.secrets.ha_token = { };
  sops.secrets.ha_token_wopr = { };
  sops.secrets."radicale/password" = { };
  sops.secrets."lubelogger/api-key" = { };
  sops.secrets."dawarich/api-key" = { };

  sops.secrets."hermes-agent/soul-triage" = {
    sopsFile = ../../../sops-nix/hermes-soul-triage.md;
    format = "binary";
  };
  sops.secrets."hermes-agent/soul-coder" = {
    sopsFile = ../../../sops-nix/hermes-soul-coder.md;
    format = "binary";
  };
  sops.secrets."hermes-agent/soul-researcher" = {
    sopsFile = ../../../sops-nix/hermes-soul-researcher.md;
    format = "binary";
  };
  sops.secrets."hermes-agent/soul-home" = {
    sopsFile = ../../../sops-nix/hermes-soul-home.md;
    format = "binary";
  };
  sops.secrets."hermes-agent/ref-caldav" = {
    sopsFile = ../../../sops-nix/hermes-ref-caldav.md;
    format = "binary";
  };
  sops.secrets."hermes-agent/ref-lubelogger" = {
    sopsFile = ../../../sops-nix/hermes-ref-lubelogger.md;
    format = "binary";
  };
  sops.secrets."hermes-agent/ref-dawarich" = {
    sopsFile = ../../../sops-nix/hermes-ref-dawarich.md;
    format = "binary";
  };
  sops.secrets."hermes-agent/ref-monitoring" = {
    sopsFile = ../../../sops-nix/hermes-ref-monitoring.md;
    format = "binary";
  };

  sops.templates."hermes-agent-env" = {
    mode = "0400";
    content = ''
      HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.sops.placeholder."hermes-agent/dashboard-username"}
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."hermes-agent/dashboard-password"}
      API_SERVER_KEY=${config.sops.placeholder."hermes-agent/api-server-key"}
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."hermes-agent/telegram-native-bot-token"}
      TELEGRAM_ALLOWED_USERS=${config.sops.placeholder."hermes-agent/telegram-allowed-users"}
      HA_TOKEN=${config.sops.placeholder.ha_token}
      HA_TOKEN_WOPR=${config.sops.placeholder.ha_token_wopr}
      OPENAI_API_KEY=${config.sops.placeholder."hermes-agent/cloud-api-key"}
      FORGEJO_PAT=${config.sops.placeholder."hermes-agent/forgejo-pat"}
      GITHUB_PAT=${config.sops.placeholder."hermes-agent/github-pat"}
      WINDOWS_MCP_TOKEN=${config.sops.placeholder."hermes-agent/windows-mcp-token"}
      CALDAV_PASSWORD=${config.sops.placeholder."radicale/password"}
      LUBELOGGER_API_KEY=${config.sops.placeholder."lubelogger/api-key"}
      DAWARICH_API_KEY=${config.sops.placeholder."dawarich/api-key"}
    '';
  };

  sops.templates."hermes-profile-env" = {
    mode = "0444";
    restartUnits = [ "hermes-agent-init.service" ];
    content = ''
      API_SERVER_KEY=${config.sops.placeholder."hermes-agent/api-server-key"}
      OPENAI_API_KEY=${config.sops.placeholder."hermes-agent/cloud-api-key"}
    '';
  };

  # Bot token only in the default home (a second profile holding it is a duplicate_credential blocker).
  sops.templates."hermes-default-env" = {
    mode = "0444";
    restartUnits = [ "hermes-agent-init.service" ];
    content = ''
      API_SERVER_KEY=${config.sops.placeholder."hermes-agent/api-server-key"}
      OPENAI_API_KEY=${config.sops.placeholder."hermes-agent/cloud-api-key"}
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."hermes-agent/telegram-native-bot-token"}
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hermes-agent 0755 root root -"
    "d /var/lib/hermes-agent/profiles 0755 root root -"
    "d /var/lib/hermes-agent/profiles/coder 0755 root root -"
    "d /var/lib/hermes-agent/profiles/researcher 0755 root root -"
    "d /var/lib/hermes-agent/profiles/home 0755 root root -"
    "d /var/lib/hermes-agent/references 0755 root root -"
  ];

  systemd.services.hermes-network-init = {
    description = "Create Hermes Agent Podman network";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-hermes-agent.service" ];
    after = [ "podman.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ config.virtualisation.podman.package ];
    script = ''
      if ! podman network exists hermes-net 2>/dev/null; then
        podman network create hermes-net --subnet 10.89.0.0/24 --gateway 10.89.0.1
      fi
    '';
  };

  systemd.services.hermes-agent-init = {
    description = "Deploy Hermes Agent configuration and profiles";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-secrets-rendered.service" ];
    requires = [ "sops-secrets-rendered.service" ];
    before = [ "podman-hermes-agent.service" ];
    restartTriggers = [
      config.sops.templates."hermes-profile-env".file
      config.sops.templates."hermes-default-env".file
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.coreutils ];
    script = ''
      # Default profile
      cp ${hermesConfigYaml} /var/lib/hermes-agent/config.yaml
      chmod 600 /var/lib/hermes-agent/config.yaml
      cp ${config.sops.secrets."hermes-agent/soul-triage".path} /var/lib/hermes-agent/SOUL.md
      chmod 644 /var/lib/hermes-agent/SOUL.md
      cp ${config.sops.templates."hermes-default-env".path} /var/lib/hermes-agent/.env
      chmod 644 /var/lib/hermes-agent/.env

      # Delegation script
      cp ${delegateScript} /var/lib/hermes-agent/delegate.py
      chmod 755 /var/lib/hermes-agent/delegate.py

      # API reference files
      cp ${
        config.sops.secrets."hermes-agent/ref-caldav".path
      } /var/lib/hermes-agent/references/caldav-api.md
      cp ${
        config.sops.secrets."hermes-agent/ref-lubelogger".path
      } /var/lib/hermes-agent/references/lubelogger-api.md
      cp ${
        config.sops.secrets."hermes-agent/ref-dawarich".path
      } /var/lib/hermes-agent/references/dawarich-api.md
      cp ${
        config.sops.secrets."hermes-agent/ref-monitoring".path
      } /var/lib/hermes-agent/references/monitoring-api.md
      chmod 644 /var/lib/hermes-agent/references/*.md

      # Coder profile
      cp ${coderConfigYaml} /var/lib/hermes-agent/profiles/coder/config.yaml
      chmod 600 /var/lib/hermes-agent/profiles/coder/config.yaml
      cp ${
        config.sops.secrets."hermes-agent/soul-coder".path
      } /var/lib/hermes-agent/profiles/coder/SOUL.md
      chmod 644 /var/lib/hermes-agent/profiles/coder/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/profiles/coder/.env
      chmod 644 /var/lib/hermes-agent/profiles/coder/.env

      # Researcher profile
      cp ${researcherConfigYaml} /var/lib/hermes-agent/profiles/researcher/config.yaml
      chmod 600 /var/lib/hermes-agent/profiles/researcher/config.yaml
      cp ${
        config.sops.secrets."hermes-agent/soul-researcher".path
      } /var/lib/hermes-agent/profiles/researcher/SOUL.md
      chmod 644 /var/lib/hermes-agent/profiles/researcher/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/profiles/researcher/.env
      chmod 644 /var/lib/hermes-agent/profiles/researcher/.env

      # Home profile
      cp ${homeConfigYaml} /var/lib/hermes-agent/profiles/home/config.yaml
      chmod 600 /var/lib/hermes-agent/profiles/home/config.yaml
      cp ${config.sops.secrets."hermes-agent/soul-home".path} /var/lib/hermes-agent/profiles/home/SOUL.md
      chmod 644 /var/lib/hermes-agent/profiles/home/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/profiles/home/.env
      chmod 644 /var/lib/hermes-agent/profiles/home/.env
    '';
  };

  systemd.services.hermes-dashboard-proxy = {
    description = "Proxy Hermes dashboard to Tailscale interface";
    after = [
      "network-online.target"
      "tailscaled.service"
      "podman-hermes-agent.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.socat
      pkgs.tailscale
    ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "hermes-dashboard-proxy" ''
        TS_IP=$(tailscale ip -4)
        exec socat TCP-LISTEN:9119,bind="$TS_IP",reuseaddr,fork TCP:127.0.0.1:9119
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.services.hermes-api-proxy = {
    description = "Proxy Hermes API to Tailscale interface";
    after = [
      "network-online.target"
      "tailscaled.service"
      "podman-hermes-agent.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.socat
      pkgs.tailscale
    ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "hermes-api-proxy" ''
        TS_IP=$(tailscale ip -4)
        exec socat TCP-LISTEN:8642,bind="$TS_IP",reuseaddr,fork TCP:127.0.0.1:8642
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  virtualisation.oci-containers.containers.hermes-agent = {
    image = "docker.io/nousresearch/hermes-agent:v2026.9.24";
    autoStart = true;
    extraOptions = [
      "--network=hermes-net"
      "--ip=10.89.0.2"
      "--add-host=host.containers.internal:host-gateway"
      "--add-host=shikisha:100.67.20.13"
      "--add-host=wopr:100.100.21.96"
      "-p"
      "127.0.0.1:9119:9119"
      "-p"
      "127.0.0.1:8642:8642"
      "--cap-drop=ALL"
      "--cap-add=DAC_OVERRIDE"
      "--cap-add=CHOWN"
      "--cap-add=FOWNER"
      "--cap-add=SETUID"
      "--cap-add=SETGID"
      "--security-opt=no-new-privileges"
      "--pids-limit=2048"
    ];
    volumes = [
      "/var/lib/hermes-agent:/opt/data"
    ];
    environmentFiles = [
      config.sops.templates."hermes-agent-env".path
    ];
    environment = {
      HERMES_HOME = "/opt/data";
      HERMES_WRITE_SAFE_ROOT = "/opt/data";
      HERMES_DASHBOARD = "1";
      HERMES_TIMEZONE = "America/Denver";
      TZ = "America/Denver";
      HERMES_REDACT_SECRETS = "true";
      API_SERVER_ENABLED = "true";
      API_SERVER_HOST = "0.0.0.0";
      HA_URL = "http://shikisha:8123";
      HA_URL_WOPR = "http://wopr:8123";
      CALDAV_URL = "http://shikisha:5232";
      CALDAV_USER = "patrick";
      LUBELOGGER_URL = "http://shikisha:18080";
      DAWARICH_URL = "http://shikisha:31122";
      PROMETHEUS_URL = "http://shikisha:9090";
      LOKI_URL = "http://shikisha:3100";
    };
    cmd = [
      "gateway"
      "run"
    ];
  };

  systemd.services.podman-hermes-agent = {
    after = [ "sops-secrets-rendered.service" ];
    requires = [ "sops-secrets-rendered.service" ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    8642
    9119
  ];
}
