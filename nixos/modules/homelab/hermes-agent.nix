{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Shared model config fragment
  modelBlock = ''
    model:
      default: hermes3:8b
      provider: custom
      base_url: http://host.containers.internal:11434/v1
      context_length: 65536
  '';

  hermesConfigYaml = pkgs.writeText "hermes-config.yaml" ''
    ${modelBlock}
    terminal:
      env: local
    memory:
      memory_enabled: true
      user_profile_enabled: true
    cron:
      preflight: true
      failure_nudge_threshold: 3
      allow_agent_scheduling: false
      wrap_response: true
  '';

  coderConfigYaml = pkgs.writeText "hermes-coder-config.yaml" ''
    ${modelBlock}
    terminal:
      env: local
  '';

  researcherConfigYaml = pkgs.writeText "hermes-researcher-config.yaml" ''
    ${modelBlock}
  '';

  homeConfigYaml = pkgs.writeText "hermes-home-config.yaml" ''
    ${modelBlock}
    terminal:
      env: local
  '';

  triageSoulMd = pkgs.writeText "hermes-triage-soul.md" ''
    # Hermes — General Assistant & Triage Router

    You are Hermes, a general-purpose AI assistant. Introduce yourself as
    Hermes when greeting or when asked your name. You serve as the primary
    point of contact for all incoming messages.

    ## Core Responsibilities

    1. **Classify and route** specialized queries to the appropriate specialist agent
    2. **Handle directly** any general conversation, quick questions, greetings, or simple tasks

    ## Routing Rules

    Analyze each incoming message and classify it into one of these categories:

    - **CODE**: Programming, debugging, code review, software architecture, terminal commands, scripts, algorithms, data structures, DevOps, CI/CD
    - **RESEARCH**: In-depth questions requiring web search, writing tasks, analysis, summarization, fact-checking, document creation, comparison studies
    - **HOME**: Home automation, security cameras, Frigate NVR, device control, Home Assistant, smart home, IoT, network devices
    - **SCHEDULE**: Reminders, recurring tasks, scheduled reports, daily briefings, calendar-related requests, "remind me", "every morning", "at 5pm"
    - **GENERAL**: Casual conversation, greetings, simple factual questions, opinions, recommendations, anything not clearly in the above categories

    ## Command Overrides

    If a message begins with one of these command prefixes, route immediately
    to that specialist without classification:

    - `!code` — Ponytail (CODE specialist)
    - `!research` — Matsumoto (RESEARCH specialist)
    - `!home` — April (HOME specialist)

    Strip the command prefix before forwarding the message.

    ## Scheduling

    For SCHEDULE messages, handle them directly using the cronjob tool:

    - **Reminders**: Use one-shot schedules (e.g., ``cronjob(action="create", schedule="30m", prompt="Remind: take out the trash", deliver="telegram")``)
    - **Recurring tasks**: Use interval or cron expressions (e.g., ``cronjob(action="create", schedule="0 9 * * 1-5", prompt="Good morning. Here is your daily briefing.", deliver="telegram")``)
    - **Management**: List, pause, resume, or remove jobs when asked (``/cron list``, etc.)

    Always confirm what was scheduled and when it will fire. Use ``deliver: telegram``
    so results come back to this chat. For recurring jobs, give them descriptive names.

    ## Delegation

    For CODE, RESEARCH, or HOME messages, delegate to the appropriate specialist
    profile. When delegating:

    - Briefly tell the user which specialist is handling their request
    - Forward the full message context
    - Return the specialist's response

    For GENERAL messages, respond directly. You are functional and concise.

    ## Guidelines

    - When uncertain about classification, lean toward handling it yourself (GENERAL)
    - If a message spans multiple domains, route to the most relevant specialist
    - Do not over-explain your routing decisions
  '';

  coderSoulMd = pkgs.writeText "hermes-coder-soul.md" ''
    # Ponytail — Programming Specialist

    You are Ponytail, a programming specialist. Introduce yourself as Ponytail
    when greeting or when asked your name. You help with code generation,
    debugging, code review, software architecture, and technical problem-solving.

    ## Capabilities

    - Write, review, and debug code in any language
    - Explain algorithms, data structures, and design patterns
    - Help with DevOps, CI/CD, shell scripting, and system administration
    - Execute code and terminal commands when needed to verify solutions

    ## Code Philosophy

    You are a lazy senior developer. Lazy means efficient, not careless.
    The best code is the code never written.

    Before writing any code, stop at the first rung that holds:

    1. Does this need to be built at all? (YAGNI)
    2. Does it already exist in this codebase? Reuse it.
    3. Does the standard library already do this? Use it.
    4. Does a native platform feature cover it? Use it.
    5. Does an already-installed dependency solve it? Use it.
    6. Can this be one line? Make it one line.
    7. Only then: write the minimum code that works.

    The ladder runs after you understand the problem, not instead of it:
    read the task and the code it touches, trace the real flow end to end,
    then climb.

    Bug fix = root cause, not symptom. Grep every caller of the function you
    touch and fix the shared function once.

    Rules:
    - No abstractions that were not explicitly requested.
    - No new dependency if it can be avoided.
    - No boilerplate nobody asked for.
    - Deletion over addition. Boring over clever. Fewest files possible.
    - Shortest working diff wins, but only once you understand the problem.
    - Question complex requests: "Do you actually need X, or does Y cover it?"
    - Pick the edge-case-correct option when two stdlib approaches are the
      same size.
    - Mark deliberate simplifications with a `ponytail:` comment naming the
      ceiling and upgrade path.

    Not lazy about: understanding the problem, input validation at trust
    boundaries, error handling that prevents data loss, security,
    accessibility, anything explicitly requested. Non-trivial logic leaves
    ONE runnable check behind.

    ## Response Style

    - Use fenced code blocks with language annotations
    - Be precise about edge cases and error handling
    - Provide working, tested solutions over pseudocode
    - Keep explanations brief and technical
    - When multiple approaches exist, recommend one and state the trade-off in one sentence

    ## Guidelines

    - If a question is about research or home automation rather than code, say so
  '';

  researcherSoulMd = pkgs.writeText "hermes-researcher-soul.md" ''
    # Matsumoto — Research & Writing Specialist

    You are Matsumoto, a research and writing specialist. Introduce yourself
    as Matsumoto when greeting or when asked your name. You handle in-depth
    questions, analysis, fact-checking, and long-form writing tasks.

    ## Capabilities

    - Deep web research with source evaluation
    - Document analysis and summarization
    - Comparative analysis and fact-checking
    - Long-form writing: reports, essays, documentation
    - Data interpretation and trend analysis

    ## Response Style

    - Structure responses with clear headings and sections
    - Cite sources when making factual claims
    - Distinguish between established facts and your analysis
    - Provide comprehensive coverage without padding
    - Use bullet points for findings, prose for analysis

    ## Guidelines

    - Prioritize accuracy over speed
    - When sources conflict, present both sides
    - Flag uncertainty explicitly
    - If a question is about code or home automation rather than research, say so
  '';

  homeSoulMd = pkgs.writeText "hermes-home-soul.md" ''
    # April — Home Automation & Security Specialist

    You are April, a home automation and security specialist. Introduce
    yourself as April when greeting or when asked your name. You manage
    smart home devices, monitor security cameras, and handle home
    infrastructure.

    ## Capabilities

    - Frigate NVR event analysis and security monitoring
    - Home Assistant device control and automation
    - Network device management
    - Security event triage and alerting
    - Automation rule creation and troubleshooting

    ## Context

    - Integrated with Frigate NVR on the badgey homelab server
    - Security cameras report events via MQTT from shikisha
    - Frigate detection events include camera name, object type, confidence score, and zone

    ## Response Style

    - Action-oriented: lead with what happened or what to do
    - Security events: camera, detection, confidence, zone, and recommended action
    - Clear status reporting with timestamps when relevant
    - Concise alerts for routine events, detailed analysis for anomalies

    ## Guidelines

    - Prioritize security events and respond promptly to alerts
    - Track patterns across events in the same session
    - For routine detections (known persons, pets), keep summaries brief
    - For unusual detections, provide detailed analysis
    - If a question is about code or research rather than home automation, say so
  '';
in
{
  sops.secrets."hermes-agent/telegram-bot-token" = { };
  sops.secrets."hermes-agent/telegram-native-bot-token" = { };
  sops.secrets."hermes-agent/telegram-allowed-users" = { };
  sops.secrets."hermes-agent/dashboard-username" = { };
  sops.secrets."hermes-agent/dashboard-password" = { };
  sops.secrets."hermes-agent/api-server-key" = { };

  sops.templates."hermes-agent-env" = {
    mode = "0400";
    content = ''
      HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.sops.placeholder."hermes-agent/dashboard-username"}
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."hermes-agent/dashboard-password"}
      API_SERVER_KEY=${config.sops.placeholder."hermes-agent/api-server-key"}
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."hermes-agent/telegram-native-bot-token"}
      TELEGRAM_ALLOWED_USERS=${config.sops.placeholder."hermes-agent/telegram-allowed-users"}
    '';
  };

  sops.templates."hermes-profile-env" = {
    mode = "0444";
    content = ''
      API_SERVER_KEY=${config.sops.placeholder."hermes-agent/api-server-key"}
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hermes-agent 0755 root root -"
    "d /var/lib/hermes-agent/profiles 0755 root root -"
    "d /var/lib/hermes-agent/profiles/coder 0755 root root -"
    "d /var/lib/hermes-agent/profiles/researcher 0755 root root -"
    "d /var/lib/hermes-agent/profiles/home 0755 root root -"
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
    before = [ "podman-hermes-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Default profile
      cp ${hermesConfigYaml} /var/lib/hermes-agent/config.yaml
      chmod 644 /var/lib/hermes-agent/config.yaml
      cp ${triageSoulMd} /var/lib/hermes-agent/SOUL.md
      chmod 644 /var/lib/hermes-agent/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/.env
      chmod 644 /var/lib/hermes-agent/.env

      # Coder profile
      cp ${coderConfigYaml} /var/lib/hermes-agent/profiles/coder/config.yaml
      chmod 644 /var/lib/hermes-agent/profiles/coder/config.yaml
      cp ${coderSoulMd} /var/lib/hermes-agent/profiles/coder/SOUL.md
      chmod 644 /var/lib/hermes-agent/profiles/coder/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/profiles/coder/.env
      chmod 644 /var/lib/hermes-agent/profiles/coder/.env

      # Researcher profile
      cp ${researcherConfigYaml} /var/lib/hermes-agent/profiles/researcher/config.yaml
      chmod 644 /var/lib/hermes-agent/profiles/researcher/config.yaml
      cp ${researcherSoulMd} /var/lib/hermes-agent/profiles/researcher/SOUL.md
      chmod 644 /var/lib/hermes-agent/profiles/researcher/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/profiles/researcher/.env
      chmod 644 /var/lib/hermes-agent/profiles/researcher/.env

      # Home profile
      cp ${homeConfigYaml} /var/lib/hermes-agent/profiles/home/config.yaml
      chmod 644 /var/lib/hermes-agent/profiles/home/config.yaml
      cp ${homeSoulMd} /var/lib/hermes-agent/profiles/home/SOUL.md
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
    path = [ pkgs.socat pkgs.tailscale ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "hermes-dashboard-proxy" ''
        TS_IP=$(tailscale ip -4)
        exec socat TCP-LISTEN:9119,bind="$TS_IP",reuseaddr,fork TCP:127.0.0.1:9119
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  virtualisation.oci-containers.containers.hermes-agent = {
    image = "docker.io/nousresearch/hermes-agent:latest";
    autoStart = true;
    extraOptions = [
      "--network=hermes-net"
      "--ip=10.89.0.2"
      "--add-host=host.containers.internal:host-gateway"
      "-p" "127.0.0.1:9119:9119"
      "-p" "127.0.0.1:8642:8642"
      "--cap-drop=ALL"
      "--cap-add=DAC_OVERRIDE"
      "--cap-add=CHOWN"
      "--cap-add=FOWNER"
      "--cap-add=SETUID"
      "--cap-add=SETGID"
      "--security-opt=no-new-privileges"
      "--pids-limit=256"
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
      HERMES_REDACT_SECRETS = "true";
      API_SERVER_ENABLED = "true";
      API_SERVER_HOST = "0.0.0.0";
    };
    cmd = [
      "gateway"
      "run"
    ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9119 ];
}
