{
  config,
  pkgs,
  lib,
  ...
}:

let
  hermesConfigYaml = pkgs.writeText "hermes-config.yaml" ''
    model:
      default: hermes3:8b
      provider: custom
      base_url: http://127.0.0.1:11434/v1
      context_length: 32000
    terminal:
      env: local
  '';
in
{
  sops.secrets."hermes-agent/telegram-bot-token" = { };
  sops.secrets."hermes-agent/telegram-allowed-users" = { };
  sops.secrets."hermes-agent/dashboard-username" = { };
  sops.secrets."hermes-agent/dashboard-password" = { };
  sops.secrets."hermes-agent/api-server-key" = { };

  sops.templates."hermes-agent-env" = {
    mode = "0400";
    content = ''
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."hermes-agent/telegram-bot-token"}
      TELEGRAM_ALLOWED_USERS=${config.sops.placeholder."hermes-agent/telegram-allowed-users"}
      HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.sops.placeholder."hermes-agent/dashboard-username"}
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."hermes-agent/dashboard-password"}
      API_SERVER_KEY=${config.sops.placeholder."hermes-agent/api-server-key"}
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hermes-agent 0755 root root -"
  ];

  systemd.services.hermes-agent-init = {
    description = "Seed Hermes Agent config.yaml if not present";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-hermes-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f /var/lib/hermes-agent/config.yaml ]; then
        cp ${hermesConfigYaml} /var/lib/hermes-agent/config.yaml
        chmod 644 /var/lib/hermes-agent/config.yaml
      fi
    '';
  };

  virtualisation.oci-containers.containers.hermes-agent = {
    image = "docker.io/nousresearch/hermes-agent:latest";
    autoStart = true;
    extraOptions = [
      "--network=host"
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
    };
    cmd = [
      "gateway"
      "run"
    ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9119 ];
}
