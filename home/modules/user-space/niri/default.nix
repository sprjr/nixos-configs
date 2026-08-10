{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.patrick.home.niri;

  isLaptop = cfg.formFactor == "laptop";

  nvidiaEnv = optionalAttrs (cfg.gpu == "nvidia") {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    NVD_BACKEND = "direct";
  };
in
{
  imports = [
    ./keybinds.nix
    ./monitors.nix
    ./fuzzel.nix
    ./waybar.nix
    ./lock.nix
    ./idle.nix
    ./wallpaper.nix
    ./notifications.nix
    ./keyring.nix
    ./window-rules.nix
    ./widgets/weather.nix
    ./widgets/stats.nix
    ./widgets/homeassistant.nix
    ./widgets/timer.nix
  ];

  options.patrick.home.niri = {
    enable = mkEnableOption "Patrick's independent Niri session";

    monitors = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Output connector name (e.g. DP-2, eDP-1).";
          };
          mode = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Resolution and refresh rate (e.g. 3840x2160@60). Null for preferred.";
            example = "3840x2160@60";
          };
          position = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Pixel position as 'XxY' (e.g. 0x0, 2304x0). Null for auto.";
            example = "2304x0";
          };
          scale = mkOption {
            type = types.float;
            default = 1.0;
            description = "Output scale factor.";
          };
          disable = mkOption {
            type = types.bool;
            default = false;
            description = "Disable this output.";
          };
        };
      });
      default = [ ];
      description = ''
        Niri output descriptors. Empty uses niri's auto-detection defaults.
        Each entry maps to an `output "<name>" { ... }` block in the niri config.
      '';
    };

    remoteMonitors = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          mode = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          position = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          scale = mkOption {
            type = types.float;
            default = 1.0;
          };
          disable = mkOption {
            type = types.bool;
            default = false;
          };
        };
      });
      default = [ ];
      description = ''
        Monitor descriptors applied by the `mon-remote` command for a remote/streaming
        session. Empty omits the command. `mon-local` re-applies `monitors`.
      '';
    };

    battery = mkOption {
      type = types.bool;
      default = false;
      description = "Show the waybar battery module (laptops only).";
    };

    formFactor = mkOption {
      type = types.enum [
        "laptop"
        "desktop"
      ];
      default = "desktop";
      description = ''
        Pointer-input tuning. "desktop" keeps the flat accel profile at sensitivity -0.6
        (gaming-mouse). "laptop" uses the adaptive accel profile at sensitivity 0 for trackpad.
      '';
    };

    gpu = mkOption {
      type = types.nullOr (
        types.enum [
          "nvidia"
          "amd"
        ]
      );
      default = null;
      description = ''
        GPU vendor for the waybar GPU widget and Nvidia session env. null omits the widget
        and adds no GPU env.
      '';
    };

    waybarExtra = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra waybar module names appended to modules-right.";
    };

    homeAssistant = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Home Assistant waybar buttons (office fan/lamp toggles, office-fan-5m script, motion
          sensor, camera feeds). Requires the sops `ha_token` secret to be decryptable on the host.
        '';
      };
      url = mkOption {
        type = types.str;
        default = "http://shikisha:8123";
        description = "Base URL of the Home Assistant instance.";
      };
    };

    signalGnomeKeyring = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Wrap signal-desktop with --password-store=gnome-libsecret (all launch paths) and pin its
        desktop entry so Signal uses the freedesktop Secret Service (gnome-keyring under Niri).
      '';
    };

    gaming = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Gaming accommodations: per-output VRR. Niri does not support tearing or direct scanout.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = lib.mkDefault ../../../../sops-nix/sops.yaml;
      defaultSopsFormat = lib.mkDefault "yaml";
      age.keyFile = lib.mkDefault "/home/patrick/.config/sops/age/keys.txt";
      secrets."cosmic/latitude" = { };
      secrets."cosmic/longitude" = { };
    };

    services.kdeconnect.enable = true;

    home.packages = with pkgs; [
      grim
      slurp
      wl-clipboard
      brightnessctl
      playerctl
      cosmic-files
      nordzy-cursor-theme
      xwayland-satellite
    ];

    programs.niri.settings = {
      input = {
        keyboard = {
          xkb.layout = "us";
          repeat-delay = 200;
          repeat-rate = 50;
        };
        mouse = {
          accel-profile = if isLaptop then "adaptive" else "flat";
          accel-speed = if isLaptop then 0.0 else -0.6;
        };
        touchpad = {
          natural-scroll = true;
          dwt = true;
          accel-profile = "adaptive";
          click-method = "clickfinger";
        };
        focus-follows-mouse.enable = true;
      };

      layout = {
        gaps = 10;
        center-focused-column = "never";
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        default-column-width.proportion = 1.0 / 2.0;
        border = {
          enable = true;
          width = 2;
          active-color = "#b4befe";
          inactive-color = "#313244";
        };
        focus-ring.enable = false;
      };

      cursor = {
        xcursor-theme = "Nordzy-catppuccin-frappe-dark";
        xcursor-size = 24;
      };

      prefer-no-csd = true;
      screenshot-path = null;

      environment =
        {
          XCURSOR_SIZE = "24";
          XCURSOR_THEME = "Nordzy-catppuccin-frappe-dark";
        }
        // nvidiaEnv;

      animations = {
        window-open.spring = {
          damping-ratio = 0.8;
          stiffness = 500;
          epsilon = 0.001;
        };
        window-close.spring = {
          damping-ratio = 0.8;
          stiffness = 500;
          epsilon = 0.001;
        };
        workspace-switch.spring = {
          damping-ratio = 1.0;
          stiffness = 500;
          epsilon = 0.001;
        };
        horizontal-view-movement.spring = {
          damping-ratio = 1.0;
          stiffness = 800;
          epsilon = 0.001;
        };
      };

      spawn-at-startup = [
        { command = [ "systemctl" "--user" "--no-block" "start" "niri-session.target" ]; }
        { command = [ "gnome-keyring-daemon" "--start" "--components=secrets" ]; }
        { command = [ "wl-paste" "--watch" "cliphist" "store" ]; }
        { command = [ "fcitx5" "-d" "--replace" ]; }
        { command = [ "xwayland-satellite" ]; }
      ];
    };

    # Niri-only target; PartOf stops daemons on logout.
    systemd.user.targets.niri-session = {
      Unit = {
        Description = "Niri session (user services scoped to Niri only)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.polkit-gnome-agent = {
      Unit = {
        Description = "polkit-gnome authentication agent";
        PartOf = [ "niri-session.target" ];
        After = [ "niri-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "niri-session.target" ];
    };
  };
}
