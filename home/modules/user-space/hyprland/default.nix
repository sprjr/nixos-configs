{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.patrick.home.hyprland;

  isLaptop = cfg.formFactor == "laptop";

  # Catppuccin Mocha border colors (rest of the palette lives per-app).
  activeBorder = "rgba(b4befeff) rgba(89b4faff) 45deg";
  inactiveBorder = "rgba(313244aa)";

  # Nvidia compositor env (seanix).
  nvidiaEnv = optionals (cfg.gpu == "nvidia") [
    "LIBVA_DRIVER_NAME,nvidia"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    "GBM_BACKEND,nvidia-drm"
    "NVD_BACKEND,direct"
    "WLR_NO_HARDWARE_CURSORS,1"
  ];

  # Archive Hyprland log off tmpfs for crash investigation.
  logArchiver = pkgs.writeShellApplication {
    name = "hyprland-log-archive";
    runtimeInputs = with pkgs; [ coreutils findutils ];
    text = ''
      src="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/hyprland.log"
      dest="''${XDG_STATE_HOME:-$HOME/.local/state}/hyprland"
      mkdir -p "$dest"
      # Prune before writing so a night of crash-looping can't accumulate indefinitely.
      find "$dest" -maxdepth 1 -name 'session-*.log' -mtime +14 -delete
      # Cap at 512M to bound runaway scan storms.
      tail -n +1 -F "$src" | head -c 512M > "$dest/session-$(date +%Y%m%d-%H%M%S).log"
    '';
  };
in
{
  imports = [
    ./keybinds.nix
    ./monitors.nix
    ./fuzzel.nix
    ./waybar.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./wallpaper.nix
    ./notifications.nix
    ./keyring.nix
    ./widgets/weather.nix
    ./widgets/ip.nix
    ./widgets/stats.nix
    ./widgets/homeassistant.nix
    ./widgets/timer.nix
  ];

  options.patrick.home.hyprland = {
    enable = mkEnableOption "Patrick's independent Hyprland session";

    monitors = mkOption {
      type = types.listOf types.str;
      default = [ ",preferred,auto,auto" ];
      description = ''
        Hyprland monitor descriptors. Default is a single auto-fallback line that adapts to
        any laptop/hotplugged output. Multi-monitor hosts (seanix) pass explicit descriptors
        and should keep ",preferred,auto,auto" last for hotplug.
      '';
      example = [
        "DP-2,3840x2160@60,1920x1080,1.7"
        ",preferred,auto,auto"
      ];
    };

    remoteMonitors = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Monitor descriptors applied by the `mon-remote` command for a remote/streaming session
        (e.g. a single streaming head with the desktop outputs disabled). Empty omits the command.
        `mon-local` re-applies the `monitors` list. Both dispatch to hyprctl inside a Hyprland
        session and fall back to the KDE ~/.local/bin/switch-*.sh scripts otherwise.
      '';
      example = [
        "HDMI-A-1,1920x1080@60,0x0,1"
        "DP-1,disable"
      ];
    };

    battery = mkOption {
      type = types.bool;
      default = false;
      description = "Show the waybar battery module (laptops only).";
    };

    formFactor = mkOption {
      type = types.enum [ "laptop" "desktop" ];
      default = "desktop";
      description = ''
        Pointer-input tuning. "desktop" keeps the flat accel profile at sensitivity -0.6
        (gaming-mouse / KDE parity, seanix). "laptop" uses the adaptive accel profile at
        sensitivity 0 so the trackpad tracks at normal speed.
      '';
    };

    gpu = mkOption {
      type = types.nullOr (types.enum [ "nvidia" "amd" ]);
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
          sensor, camera feeds) mirroring the Darwin sketchybar. Requires the sops `ha_token`
          secret to be decryptable on the host.
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
        desktop entry so Signal uses the freedesktop Secret Service (gnome-keyring under Hyprland).
        Enable only on hosts where Signal is installed — it pulls signal-desktop into the closure.
        Requires a one-time Signal re-link off the old kwallet6 key.
      '';
    };

    gaming = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Gaming accommodations for a dedicated gaming host: fullscreen VRR (misc:vrr = 2), direct
          scanout for fullscreen games (lower latency), and an idleinhibit-on-fullscreen window rule
          so controller-only play never dims or locks the screen. Off elsewhere.
        '';
      };
      tearing = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allow tearing for lower latency on fixed-refresh/competitive play (adds allow_tearing, an
          `immediate` window rule, and direct_scanout = 2). Redundant with VRR on a G-Sync/FreeSync
          panel — leave off if you rely on VRR.
        '';
      };
    };

    debugLogging = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Temporary instrumentation for the aquamarine SEGV in CBackend::dispatchIdle (seanix,
        Jul 21 / Jul 27 2026). Turns off debug:disable_logs and archives the session log off
        tmpfs to ~/.local/state/hyprland/session-<timestamp>.log, which is what the crash
        report's fixed-size tail cannot give — the tail is entirely saturated by the connector
        rescan loop, so the triggering event is pushed out of it.

        TEARDOWN: set back to false once the trigger is identified. That reverts disable_logs to
        the upstream default and drops the archiver unit; the archives under
        ~/.local/state/hyprland/ are not garbage-collected by Nix and must be deleted by hand.
        journald persistence is NOT part of this — Storage=persistent is already the NixOS
        default and stays on regardless.
      '';
    };
  };

  config = mkIf cfg.enable {
    # mkDefault: coexists with cosmic.nix sops declarations.
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
      # polkit_gnome omitted: its XDG autostart races polkit-gnome-agent.service below.
      cosmic-files
      nordzy-cursor-theme
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      systemd.enable = false;
      # Pin the config format so it doesn't silently switch to "lua" at stateVersion 26.05.
      configType = "hyprlang";

      settings = {
        "$terminal" = "ghostty";
        "$fileManager" = "cosmic-files";
        "$mainMod" = "SUPER";

        env = [
          "XCURSOR_SIZE,24"
          "XCURSOR_THEME,Nordzy-catppuccin-frappe-dark"
          "HYPRCURSOR_SIZE,24"
          "HYPRCURSOR_THEME,Nordzy-hyprcursors"
        ] ++ nvidiaEnv;

        cursor = mkIf (cfg.gpu == "nvidia") {
          no_hardware_cursors = true;
        };

        # Session daemons: scoped to hyprland-session.target, not graphical-session.target.
        exec-once = [
          # uwsm finalize exports env, then start target. `;` sequences (exec-once is concurrent);
          # --no-block avoids deadlock. Bare uwsm from PATH to match system uwsm.
          "uwsm finalize; systemctl --user --no-block start hyprland-session.target"
          # Start Secret Service for Electron apps (no kwallet under Hyprland).
          "gnome-keyring-daemon --start --components=secrets"
          "hyprctl setcursor Nordzy-catppuccin-frappe-dark 24"
          "wl-paste --watch cliphist store"
          "fcitx5 -d --replace"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 0;
          "col.active_border" = activeBorder;
          "col.inactive_border" = inactiveBorder;
          layout = "dwindle";
          allow_tearing = cfg.gaming.enable && cfg.gaming.tearing;
          resize_on_border = true;
        };

        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = true;
          bezier = [
            "easeOutQuint,0.23,1,0.32,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
          ];
          animation = [
            "global,1,10,default"
            "border,1,5.39,easeOutQuint"
            "windows,1,4.79,easeOutQuint"
            "windowsIn,1,4.1,easeOutQuint,popin 87%"
            "windowsOut,1,1.49,linear,popin 87%"
            "fadeIn,1,1.73,almostLinear"
            "fadeOut,1,1.46,almostLinear"
            "fade,1,3.03,quick"
            "layers,1,3.81,easeOutQuint"
            "layersIn,1,4,easeOutQuint,fade"
            "layersOut,1,1.5,linear,fade"
            "workspaces,1,1.94,almostLinear,fade"
            "workspacesIn,1,1.21,almostLinear,fade"
            "workspacesOut,1,1.94,almostLinear,fade"
          ];
        };

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          # Desktop: flat/-0.6 for gaming mice. Laptop: adaptive/0 for trackpad.
          sensitivity = if isLaptop then 0 else -0.6;
          accel_profile = if isLaptop then "adaptive" else "flat";
          repeat_delay = 200;
          repeat_rate = 50;
          touchpad = {
            natural_scroll = true;
            clickfinger_behavior = true;
            disable_while_typing = true;
          };
        };

        dwindle = {
          preserve_split = true;
        };

        # Hyprland 0.51+ gesture syntax (replaces the removed gestures:workspace_swipe).
        gesture = [ "3, horizontal, workspace" ];

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        } // optionalAttrs cfg.gaming.enable { vrr = 2; };

        # Direct scanout: 2 permits tearing, 1 bypasses compositing only.
        render = optionalAttrs cfg.gaming.enable {
          direct_scanout = if cfg.gaming.tearing then 2 else 1;
        };

        # Full logging only useful with the log archiver; crash tail gets saturated by scan spam.
        debug = {
          disable_logs = !cfg.debugLogging;
        };
      };
    };

    # Hyprland-only target; PartOf stops daemons on logout.
    systemd.user.targets.hyprland-session = {
      Unit = {
        Description = "Hyprland session (user services scoped to Hyprland only)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
    };

    # Unit for cgroup isolation and crash restart; only one polkit agent may hold the subject.
    systemd.user.services.polkit-gnome-agent = {
      Unit = {
        Description = "polkit-gnome authentication agent";
        PartOf = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };

    systemd.user.services.hyprland-log-archive = mkIf cfg.debugLogging {
      Unit = {
        Description = "Archive the Hyprland session log off tmpfs (crash instrumentation)";
        PartOf = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = getExe logArchiver;
        # No restart: each start opens a new file; failure after 512M cap is expected.
        Restart = "no";
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };
}
