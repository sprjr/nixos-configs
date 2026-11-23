{ ags }:
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.programs.agsPanels;

  # CSS token names written to vars.css.
  colorNames = [
    "bg"
    "bg-alt"
    "bg-hover"
    "fg"
    "fg-dim"
    "accent"
    "green"
    "yellow"
    "red"
    "orange"
    "cyan"
    "purple"
    "border"
  ];

  # Stylix palette when the stylix module is loaded, Catppuccin Mocha otherwise.
  defaultColors =
    if config.lib ? stylix then
      with config.lib.stylix.colors.withHashtag;
      {
        bg = base00;
        bg-alt = base01;
        bg-hover = base02;
        fg = base05;
        fg-dim = base04;
        accent = base0D;
        green = base0B;
        yellow = base0A;
        red = base08;
        orange = base09;
        cyan = base0C;
        purple = base0E;
        border = base03;
      }
    else
      {
        bg = "#1e1e2e";
        bg-alt = "#181825";
        bg-hover = "#313244";
        fg = "#cdd6f4";
        fg-dim = "#585b70";
        accent = "#89b4fa";
        green = "#a6e3a1";
        yellow = "#f9e2af";
        red = "#f38ba8";
        orange = "#fab387";
        cyan = "#94e2d5";
        purple = "#cba6f7";
        border = "#45475a";
      };

  # Option name -> AGS window name.
  panelNames = {
    controlCenter = "control-center";
    hwMonitor = "hw-monitor";
    keybinds = "keybinds";
    phone = "phone";
  };

  enabledPanels = attrValues (filterAttrs (k: _: cfg.panels.${k}.enable) panelNames);

  features = builtins.toJSON {
    inherit (cfg.features) comin notifications ollamaUsage;
    panels = enabledPanels;
  };

  # Plain attrsets; submodule values carry _module, which toJSON can't serialise.
  keybindGroups = map (g: {
    inherit (g) title icon;
    binds = map (b: { inherit (b) keys desc; }) g.binds;
  }) cfg.keybinds;

  keybindTs = pkgs.writeText "keybind-data.ts" ''
    export type Bind = { keys: string; desc: string }
    export type Group = { title: string; icon: string; binds: Bind[] }
    export default ${builtins.toJSON keybindGroups} as Group[]
  '';

  agsConfig = pkgs.stdenv.mkDerivation {
    name = "ags-control-center-config";
    src = ./config;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
      cat > $out/vars.css << 'VARS'
      :root {
      ${concatMapStringsSep "\n" (n: "  --${n}: ${cfg.colors.${n}};") colorNames}
        --radius: 12px;
        --panel-width: 400px;
        --is-laptop: ${if cfg.laptop then "1" else "0"};
      }
      VARS
      cat > $out/features.json << 'FEATURES'
      ${features}
      FEATURES
      cp ${keybindTs} $out/keybind-data.ts
    '';
  };

  toggle =
    name: msg:
    pkgs.writeShellApplication {
      inherit name;
      text = ''ags request "${msg}"'';
    };

  kdeconnectStatus = import ./kdeconnect-status.nix {
    inherit pkgs;
    inherit (cfg.phone) bindHint;
  };

  bindType = types.submodule {
    options = {
      keys = mkOption { type = types.str; };
      desc = mkOption { type = types.str; };
    };
  };

  groupType = types.submodule {
    options = {
      title = mkOption { type = types.str; };
      icon = mkOption {
        type = types.str;
        description = "Symbolic icon name for the group header.";
      };
      binds = mkOption { type = types.listOf bindType; };
    };
  };

  panelOption =
    desc: default:
    mkOption {
      type = types.bool;
      inherit default;
      description = "Enable the ${desc}.";
    };
in
{
  options.programs.agsPanels = {
    enable = mkEnableOption "AGS control center, hardware monitor, keybind sheet and phone panel";

    systemdTarget = mkOption {
      type = types.str;
      default = "graphical-session.target";
      description = "User systemd target that starts the ags service.";
    };

    colors = genAttrs colorNames (
      n:
      mkOption {
        type = types.str;
        default = defaultColors.${n};
        defaultText = literalMD "stylix palette if loaded, else Catppuccin Mocha";
        description = "CSS color for `--${n}`.";
      }
    );

    laptop = mkOption {
      type = types.bool;
      default = false;
      description = "Laptop layout (exposed to CSS as `--is-laptop`).";
    };

    panels = {
      controlCenter.enable = panelOption "control center (`control-center-toggle`)" true;
      hwMonitor.enable = panelOption "hardware monitor (`hw-monitor-toggle`); requires `hwstat` on PATH" true;
      keybinds.enable = panelOption "keybind cheat sheet (`keybinds-toggle`)" true;
      phone.enable = panelOption "KDE Connect phone panel (`phone-panel-toggle`)" false;
    };

    keybinds = mkOption {
      type = types.listOf groupType;
      default = [ ];
      description = "Groups shown in the keybind cheat sheet.";
    };

    features = {
      comin = mkOption {
        type = types.bool;
        default = false;
        description = "Show the comin section; requires `comin-state` and `comin-fleet` on PATH.";
      };
      ollamaUsage = mkOption {
        type = types.bool;
        default = false;
        description = "Show the Ollama Cloud usage section; requires `ollama-usage` on PATH.";
      };
      notifications = mkOption {
        type = types.enum [
          "swaync"
          "hokum"
        ];
        default = "swaync";
        description = "Notification daemon driven by the header do-not-disturb button.";
      };
    };

    phone.bindHint = mkOption {
      type = types.str;
      default = "";
      example = "Super B";
      description = "Key combo shown in the waybar phone tooltip; empty omits it.";
    };

    hyprland.layerRules = mkOption {
      type = types.bool;
      default = config.wayland.windowManager.hyprland.enable;
      defaultText = literalExpression "config.wayland.windowManager.hyprland.enable";
      description = "Add Hyprland blur/slide layer rules for the panels.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.ags = {
        enable = true;
        configDir = agsConfig;
        systemd.enable = true;
        extraPackages =
          (with ags.packages.${pkgs.stdenv.hostPlatform.system}; [
            io
            astal4
            network
            bluetooth
            wireplumber
            battery
            powerprofiles
            mpris
            hyprland
          ])
          ++ [
            pkgs.libadwaita
            # nmcli for the Wi-Fi connect action
            pkgs.networkmanager
          ];
      };

      home.packages =
        [ pkgs.brightnessctl ]
        ++ optional cfg.panels.controlCenter.enable (toggle "control-center-toggle" "toggle")
        ++ optional cfg.panels.hwMonitor.enable (toggle "hw-monitor-toggle" "toggle-hw")
        ++ optional cfg.panels.keybinds.enable (toggle "keybinds-toggle" "toggle-keybinds")
        ++ optionals cfg.panels.phone.enable [
          (toggle "phone-panel-toggle" "toggle-phone")
          kdeconnectStatus
        ];

      systemd.user.services.ags = {
        Install.WantedBy = mkForce [ cfg.systemdTarget ];
        # ags bundles the config at startup; a config change must restart the running instance.
        Unit.X-Restart-Triggers = [ "${agsConfig}" ];
      };
    }

    (mkIf cfg.hyprland.layerRules {
      wayland.windowManager.hyprland.settings.layer_rule = map (ns: {
        name = ns;
        match.namespace = "^(${ns})$";
        blur = true;
        ignore_alpha = 0.0;
        animation = "slide right";
      }) enabledPanels;
    })
  ]);
}
