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

  mkModelBlock = { model, base_url ? cloudBase, context_length ? 131072, api_key ? false }:
    let keyLine = if api_key then "\n  api_key: __CLOUD_API_KEY__" else "";
    in ''
    model:
      default: ${model}
      provider: custom
      base_url: ${base_url}
      context_length: ${toString context_length}${keyLine}
  '';

  # Per-profile model assignments
  triageModel = mkModelBlock { model = "deepseek-v4-flash:0731"; api_key = true; };
  coderModel = mkModelBlock { model = "kimi-k2.7-code"; api_key = true; };
  researcherModel = mkModelBlock { model = "deepseek-v4-flash:0731"; api_key = true; };
  homeModel = mkModelBlock { model = "gemma4:31b"; context_length = 128000; api_key = true; };

  localModel = mkModelBlock {
    model = "qwen3.5:4b";
    base_url = "http://host.containers.internal:11434/v1";
    context_length = 16384;
  };

  cloudApiKeyFile = config.sops.secrets."hermes-agent/cloud-api-key".path;

  hermesConfigYaml = pkgs.writeText "hermes-config.yaml" ''
    ${triageModel}
    terminal:
      env: local
    memory:
      memory_enabled: true
      user_profile_enabled: true
    cron:
      preflight: true
      failure_nudge_threshold: 3
      allow_agent_scheduling: true
      wrap_response: true
  '';

  coderConfigYaml = pkgs.writeText "hermes-coder-config.yaml" ''
    ${coderModel}
    terminal:
      env: local
  '';

  researcherConfigYaml = pkgs.writeText "hermes-researcher-config.yaml" ''
    ${researcherModel}
  '';

  homeConfigYaml = pkgs.writeText "hermes-home-config.yaml" ''
    ${homeModel}
    terminal:
      env: local
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
      CALDAV_PASSWORD=${config.sops.placeholder."radicale/password"}
      LUBELOGGER_API_KEY=${config.sops.placeholder."lubelogger/api-key"}
      DAWARICH_API_KEY=${config.sops.placeholder."dawarich/api-key"}
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
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    before = [ "podman-hermes-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.gnused ];
    script = ''
      CLOUD_KEY=$(cat ${cloudApiKeyFile})

      # Default profile
      cp ${hermesConfigYaml} /var/lib/hermes-agent/config.yaml
      sed -i "s|__CLOUD_API_KEY__|$CLOUD_KEY|g" /var/lib/hermes-agent/config.yaml
      chmod 600 /var/lib/hermes-agent/config.yaml
      cp ${config.sops.secrets."hermes-agent/soul-triage".path} /var/lib/hermes-agent/SOUL.md
      chmod 644 /var/lib/hermes-agent/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/.env
      chmod 644 /var/lib/hermes-agent/.env

      # API reference files
      cp ${config.sops.secrets."hermes-agent/ref-caldav".path} /var/lib/hermes-agent/references/caldav-api.md
      cp ${config.sops.secrets."hermes-agent/ref-lubelogger".path} /var/lib/hermes-agent/references/lubelogger-api.md
      cp ${config.sops.secrets."hermes-agent/ref-dawarich".path} /var/lib/hermes-agent/references/dawarich-api.md
      cp ${config.sops.secrets."hermes-agent/ref-monitoring".path} /var/lib/hermes-agent/references/monitoring-api.md
      chmod 644 /var/lib/hermes-agent/references/*.md

      # Coder profile
      cp ${coderConfigYaml} /var/lib/hermes-agent/profiles/coder/config.yaml
      sed -i "s|__CLOUD_API_KEY__|$CLOUD_KEY|g" /var/lib/hermes-agent/profiles/coder/config.yaml
      chmod 600 /var/lib/hermes-agent/profiles/coder/config.yaml
      cp ${config.sops.secrets."hermes-agent/soul-coder".path} /var/lib/hermes-agent/profiles/coder/SOUL.md
      chmod 644 /var/lib/hermes-agent/profiles/coder/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/profiles/coder/.env
      chmod 644 /var/lib/hermes-agent/profiles/coder/.env

      # Researcher profile
      cp ${researcherConfigYaml} /var/lib/hermes-agent/profiles/researcher/config.yaml
      sed -i "s|__CLOUD_API_KEY__|$CLOUD_KEY|g" /var/lib/hermes-agent/profiles/researcher/config.yaml
      chmod 600 /var/lib/hermes-agent/profiles/researcher/config.yaml
      cp ${config.sops.secrets."hermes-agent/soul-researcher".path} /var/lib/hermes-agent/profiles/researcher/SOUL.md
      chmod 644 /var/lib/hermes-agent/profiles/researcher/SOUL.md
      cp ${config.sops.templates."hermes-profile-env".path} /var/lib/hermes-agent/profiles/researcher/.env
      chmod 644 /var/lib/hermes-agent/profiles/researcher/.env

      # Home profile
      cp ${homeConfigYaml} /var/lib/hermes-agent/profiles/home/config.yaml
      sed -i "s|__CLOUD_API_KEY__|$CLOUD_KEY|g" /var/lib/hermes-agent/profiles/home/config.yaml
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

  systemd.services.hermes-api-proxy = {
    description = "Proxy Hermes API to Tailscale interface";
    after = [
      "network-online.target"
      "tailscaled.service"
      "podman-hermes-agent.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.socat pkgs.tailscale ];
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
    image = "docker.io/nousresearch/hermes-agent:latest";
    autoStart = true;
    extraOptions = [
      "--network=hermes-net"
      "--ip=10.89.0.2"
      "--add-host=host.containers.internal:host-gateway"
      "--add-host=shikisha:100.67.20.13"
      "--add-host=wopr-0:100.100.21.96"
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
      TZ = "America/Denver";
      HERMES_REDACT_SECRETS = "true";
      API_SERVER_ENABLED = "true";
      API_SERVER_HOST = "0.0.0.0";
      HA_URL = "http://shikisha:8123";
      HA_URL_WOPR = "http://wopr-0:8123";
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
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8642 9119 ];
}
