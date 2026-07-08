{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Fresh, system-agnostic Hyprland session mirroring the patrick.home.cosmic gating pattern
# (home/modules/user-space/cosmic/cosmic.nix). Gated behind patrick.home.hyprland.enable
# (default false) so importing the module is inert until a host opts in. Runs unchanged on
# single-monitor laptops, docked laptops, and seanix's three-monitor Nvidia desktop.
let
  cfg = config.patrick.home.hyprland;

  # Catppuccin Mocha border colors (rest of the palette lives per-app).
  activeBorder = "rgba(b4befeff) rgba(89b4faff) 45deg";
  inactiveBorder = "rgba(313244aa)";

  # Nvidia Wayland session env (seanix). Driver/DRM/modeset stay in nvidia-seanix.nix —
  # this only sets the compositor-side environment.
  nvidiaEnv = optionals (cfg.gpu == "nvidia") [
    "LIBVA_DRIVER_NAME,nvidia"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    "GBM_BACKEND,nvidia-drm"
    "NVD_BACKEND,direct"
    "WLR_NO_HARDWARE_CURSORS,1"
  ];
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
  };

  config = mkIf cfg.enable {
    # sops: weather lat/lon reused from the COSMIC secrets. defaults use mkDefault so they
    # coexist with cosmic.nix on laptops; the secrets are declared without `mode` so they
    # merge with cosmic.nix's `mode="0600"` instead of conflicting. On seanix (no COSMIC)
    # this block stands alone.
    sops = {
      defaultSopsFile = lib.mkDefault ../../../../sops-nix/sops.yaml;
      defaultSopsFormat = lib.mkDefault "yaml";
      age.keyFile = lib.mkDefault "/home/patrick/.config/sops/age/keys.txt";
      secrets."cosmic/latitude" = { };
      secrets."cosmic/longitude" = { };
    };

    home.packages = with pkgs; [
      grim
      slurp
      wl-clipboard
      brightnessctl
      playerctl
      polkit_gnome
      cosmic-files
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      systemd.enable = true;
      # Pin the config format so it doesn't silently switch to "lua" at stateVersion 26.05.
      configType = "hyprlang";

      settings = {
        "$terminal" = "ghostty";
        "$fileManager" = "cosmic-files";
        "$mainMod" = "SUPER";

        env = nvidiaEnv;

        cursor = mkIf (cfg.gpu == "nvidia") {
          no_hardware_cursors = true;
        };

        # Session daemons are launched here (only inside a Hyprland session) rather than via
        # their home-manager systemd units, whose WantedBy=graphical-session.target would
        # otherwise start them under COSMIC/KDE too. The units are neutralized (WantedBy=[])
        # in their respective modules.
        exec-once = [
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          # Register the freedesktop Secret Service in the session (PAM already unlocked the login
          # keyring). Lets Electron/Signal use gnome-libsecret where there's no KDE kwallet.
          "gnome-keyring-daemon --start --components=secrets"
          "waybar"
          "swaync"
          "swww-daemon"
          "hypridle"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 20;
          # No active-window outline (border_size 0 removes the focus hint entirely). To keep a
          # uniform border without the highlight instead, set border_size back to 2 and point
          # col.active_border at inactiveBorder.
          border_size = 0;
          "col.active_border" = activeBorder;
          "col.inactive_border" = inactiveBorder;
          layout = "dwindle";
          allow_tearing = false;
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
          sensitivity = -0.3;
          # Flat profile disables libinput's adaptive acceleration curve for a 1:1 pointer.
          # Lower `sensitivity` toward -1.0 to slow the pointer further.
          accel_profile = "flat";
          # Copied from KDE ~/.config/kcminputrc [Keyboard] (RepeatDelay/RepeatRate).
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
        };

        # The stock suppressevent/nofocus windowrules were dropped: their hyprlang rule-field
        # names were reworked (0.51+ "rethonk") and are version-unstable. Re-add via the current
        # wiki syntax (or the Lua config) if the self-maximize / XWayland focus-steal fixes are
        # wanted.
      };
    };
  };
}
