{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.frigate-analyzer;
  stateDir = "/var/lib/frigate-analyzer";
  secrets = config.sops.secrets;

  # Created by the user with sops; absent until then, so the module runs without rules
  rulesFile = ../../../../sops-nix/frigate-analyzer-rules.yaml.enc;
  hasRules = builtins.pathExists rulesFile;

  analyzer = import ./analyzer.nix { inherit pkgs; };
  mcpServer = import ./mcp.nix { inherit pkgs; };

  configFile = pkgs.writeText "frigate-analyzer.json" (
    builtins.toJSON {
      db = "${stateDir}/events.db";
      schema = pkgs.writeText "frigate-analyzer-schema.sql" (import ./schema.nix);
      snapshot_dir = "${stateDir}/snapshots";
      frigate_url = cfg.frigateUrl;
      ollama_url = cfg.ollamaUrl;
      model = cfg.model;
      mqtt_host = cfg.mqttHost;
      mqtt_port = 1883;
      mqtt_user = "hermes";
      sweep_cameras = cfg.sweepCameras;
      sweep_interval = cfg.sweepInterval;
      max_images = cfg.maxImages;
      retention_days = cfg.retentionDays;
      metrics_port = cfg.metricsPort;
      control_port = cfg.controlPort;
      control_bind = if cfg.remoteControl.enable then "0.0.0.0" else "127.0.0.1";
      camera_context = cfg.cameraContext;
      ha_url = cfg.notify.haMobile.url;
      ha_service = cfg.notify.haMobile.service;
      notify = {
        ntfy = cfg.notify.ntfy.enable;
        telegram = cfg.notify.telegram.enable;
        ha_mobile = cfg.notify.haMobile.enable;
      };
    }
  );

  rulesCredential = lib.optional hasRules "rules:${secrets."frigate-analyzer/rules".path}";

  credentials = [
    "mqtt-password:${secrets."mosquitto/hermes-password".path}"
  ]
  ++ lib.optional cfg.notify.ntfy.enable "ntfy-url:${secrets.${cfg.notify.ntfy.urlSecret}.path}"
  ++ lib.optionals cfg.notify.telegram.enable [
    "telegram-token:${secrets."hermes-agent/telegram-bot-token".path}"
    "telegram-users:${secrets."hermes-agent/telegram-allowed-users".path}"
  ]
  ++ lib.optional cfg.notify.haMobile.enable "ha-token:${secrets.ha_token.path}"
  ++ lib.optional cfg.remoteControl.enable "control-token:${secrets."frigate/control-token".path}"
  ++ rulesCredential;

  hardening = {
    User = "frigate-analyzer";
    Group = "frigate-analyzer";
    StateDirectory = "frigate-analyzer";
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
  };
in
{
  options.services.frigate-analyzer = {
    enable = lib.mkEnableOption "Frigate review analysis with a local vision model";

    model = lib.mkOption {
      type = lib.types.str;
      default = "gemma3:4b";
      description = "Ollama vision model used for stills.";
    };

    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Ollama API base URL.";
    };

    frigateUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:5000";
      description = "Frigate base URL (unauthenticated nginx port).";
    };

    mqttHost = lib.mkOption {
      type = lib.types.str;
      default = "shikisha";
      description = "MQTT broker that receives frigate/reviews.";
    };

    sweepCameras = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "front_door" ];
      description = "Cameras checked periodically for packages.";
    };

    sweepInterval = lib.mkOption {
      type = lib.types.int;
      default = 180;
      description = "Seconds between package sweeps.";
    };

    maxImages = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Maximum snapshots sent to the model per review.";
    };

    retentionDays = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = "Days to keep snapshot JPEGs of unpinned events. Rows are kept forever.";
    };

    cameraContext = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        front_door = "Faces the front porch, walkway and driveway; the front door is just out of frame.";
        garage = "Faces the garage door and driveway.";
      };
      description = "Per-camera scene description given to the model.";
    };

    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 9465;
      description = "Prometheus metrics port (opened on tailscale0).";
    };

    controlPort = lib.mkOption {
      type = lib.types.port;
      default = 9466;
      description = "Control endpoint port: POST /assess (live check), GET /recent (recent events).";
    };

    remoteControl = {
      # Requires the sops key frigate/control-token in sops-nix/sops.yaml
      enable = lib.mkEnableOption "bearer-token access to the control endpoint from other hosts";
      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "tailscale0" ];
        description = "Interfaces on which the control port is opened.";
      };
    };

    mcpPort = lib.mkOption {
      type = lib.types.port;
      default = 8650;
      description = "MCP streamable-HTTP port.";
    };

    mcpInterface = lib.mkOption {
      type = lib.types.str;
      default = "podman1";
      description = "Bridge interface of hermes-net; the MCP port is opened only there.";
    };

    notify = {
      ntfy = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Send rule matches to ntfy.";
        };
        urlSecret = lib.mkOption {
          type = lib.types.str;
          default = "monitoring/ntfy/frigate-events-url";
          description = "sops secret holding the ntfy topic URL.";
        };
      };

      telegram.enable = lib.mkEnableOption "Telegram notifications via the hermes bot";

      haMobile = {
        enable = lib.mkEnableOption "Home Assistant mobile app notifications";
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://shikisha:8123";
          description = "Home Assistant base URL.";
        };
        service = lib.mkOption {
          type = lib.types.str;
          default = "mobile_app_pixel_8";
          description = "notify service name.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.mkMerge [
      { "mosquitto/hermes-password" = { }; }
      (lib.mkIf cfg.notify.ntfy.enable { ${cfg.notify.ntfy.urlSecret} = { }; })
      (lib.mkIf cfg.notify.telegram.enable {
        "hermes-agent/telegram-bot-token" = { };
        "hermes-agent/telegram-allowed-users" = { };
      })
      (lib.mkIf cfg.notify.haMobile.enable { ha_token = { }; })
      (lib.mkIf cfg.remoteControl.enable {
        "frigate/control-token".restartUnits = [ "frigate-analyzer.service" ];
      })
      (lib.mkIf hasRules {
        "frigate-analyzer/rules" = {
          sopsFile = rulesFile;
          format = "binary";
          restartUnits = [
            "frigate-analyzer.service"
            "frigate-analyzer-mcp.service"
          ];
        };
      })
    ];

    users.users.frigate-analyzer = {
      isSystemUser = true;
      group = "frigate-analyzer";
      home = stateDir;
    };
    users.groups.frigate-analyzer = { };

    environment.systemPackages = [
      pkgs.sqlite
      analyzer
    ];
    environment.etc."frigate-analyzer/config.json".source = configFile;

    systemd.services.frigate-analyzer = {
      description = "Analyze Frigate reviews with a local vision model";
      after = [
        "network-online.target"
        "ollama.service"
        "frigate.service"
        "sops-secrets-rendered.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "sops-secrets-rendered.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ configFile ];
      serviceConfig = hardening // {
        ExecStart = "${analyzer}/bin/frigate-analyzer run --config ${configFile}";
        LoadCredential = credentials;
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    systemd.services.frigate-analyzer-mcp = {
      description = "MCP server over the Frigate analyzer database";
      after = [ "frigate-analyzer.service" ];
      wants = [ "frigate-analyzer.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = hardening // {
        ExecStart = "${mcpServer}/bin/frigate-analyzer-mcp --config ${configFile} --host 0.0.0.0 --port ${toString cfg.mcpPort}";
        LoadCredential = rulesCredential;
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    systemd.services.frigate-analyzer-prune = {
      description = "Prune old Frigate analyzer snapshots";
      serviceConfig = hardening // {
        Type = "oneshot";
        ExecStart = "${analyzer}/bin/frigate-analyzer prune --config ${configFile}";
      };
    };

    systemd.timers.frigate-analyzer-prune = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    networking.firewall.interfaces = lib.mkMerge [
      {
        tailscale0.allowedTCPPorts = [ cfg.metricsPort ];
        ${cfg.mcpInterface}.allowedTCPPorts = [ cfg.mcpPort ];
      }
      (lib.mkIf cfg.remoteControl.enable (
        lib.genAttrs cfg.remoteControl.interfaces (_: {
          allowedTCPPorts = [ cfg.controlPort ];
        })
      ))
    ];
  };
}
