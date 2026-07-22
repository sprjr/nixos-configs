{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Top waybar. Built-in modules for workspaces/window/clock/cpu/memory/temperature/network/
# pulseaudio/tray; custom modules (weather, public/private IP, gpu, swaync toggle) are
# provided as PATH binaries by widgets/*.nix and notifications.nix. Temperature uses no
# hardcoded hwmon path (waybar auto-detects). battery is shown only when the `battery`
# option is set, gpu only when `gpu` is set. `waybarExtra` appends module names.
# Catppuccin Mocha styling. Runs as a systemd unit on hyprland-session.target so crashes
# restart it and config changes apply on switch (sd-switch) instead of waiting for re-login.
let
  cfg = config.patrick.home.hyprland;

  # User-space Bluetooth power toggle (no rfkill/root needed); blueman-manager handles pairing.
  btToggle = pkgs.writeShellApplication {
    name = "bt-toggle";
    runtimeInputs = with pkgs; [
      bluez
      gnugrep
    ];
    text = ''
      if bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power off
      else
        bluetoothctl power on
      fi
    '';
  };

  powerMenu = pkgs.writeShellApplication {
    name = "waybar-power-menu";
    runtimeInputs = with pkgs; [ fuzzel ];
    text = ''
      choice=$(printf "  Lock\n  Logout\n  Reboot\n  Shutdown" | fuzzel --dmenu --prompt "Power  ")
      case "$choice" in
        *Lock) hyprlock ;;
        *Logout) hyprctl dispatch exit ;;
        *Reboot) systemctl reboot ;;
        *Shutdown) systemctl poweroff ;;
      esac
    '';
  };

  clipboardBrowse = pkgs.writeShellApplication {
    name = "waybar-clipboard";
    runtimeInputs = with pkgs; [
      cliphist
      fuzzel
      wl-clipboard
    ];
    text = ''
      cliphist list | fuzzel --dmenu --prompt "Clipboard  " | cliphist decode | wl-copy
    '';
  };

  ha = cfg.homeAssistant;

  # Home Assistant control cluster + timer, placed left to mirror the Darwin sketchybar layout.
  haModules = optionals ha.enable [
    "custom/ha-fan"
    "custom/ha-lamp"
    "custom/ha-office-fan"
    "custom/ha-motion"
    "custom/ha-cameras"
  ];

  modulesLeft =
    [
      "hyprland/workspaces"
    ]
    ++ haModules
    ++ [
      "custom/timer"
      "custom/weather"
      "custom/public-ip"
    ];

  modulesRight =
    [
      "pulseaudio"
      "bluetooth"
      "cpu"
      "memory"
      "disk"
      "temperature"
    ]
    ++ optional (cfg.gpu != null) "custom/gpu"
    ++ [ "power-profiles-daemon" ]
    ++ optional cfg.battery "battery"
    ++ [
      "hyprland/language"
      "privacy"
      "idle_inhibitor"
      "systemd-failed-units"
      "custom/clipboard"
      "custom/color-picker"
      "tray"
      "custom/power-menu"
      "custom/notification"
    ]
    ++ cfg.waybarExtra;
in
{
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.blueman
      pkgs.cliphist
      pkgs.hyprpicker
      btToggle
      powerMenu
      clipboardBrowse
    ];

    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        targets = [ "hyprland-session.target" ];
      };
      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 6;

        modules-left = modulesLeft;
        modules-center = [ "mpris" "clock" ];
        modules-right = modulesRight;

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{id}";
        };

        clock = {
          format = "{:%a %d %b  %H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };

        cpu = {
          format = "󰻠 {usage}%";
          interval = 2;
        };

        memory = {
          format = "󰍛 {used:0.1f}G/{total:0.1f}G";
          interval = 5;
        };

        temperature = {
          critical-threshold = 80;
          format = "{temperatureC}°C ";
          format-icons = [ "" "" "" "" "" ];
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        bluetooth = {
          format = "󰂯";
          format-connected = "󰂱 {num_connections}";
          format-disabled = "󰂲";
          format-off = "󰂲";
          tooltip-format = "{controller_alias}\n{status}";
          tooltip-format-connected = "{controller_alias}\n{device_enumerate}";
          # Left-click toggles adapter power, right-click opens the manager.
          on-click = "bt-toggle";
          on-click-right = "blueman-manager";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        };

        tray.spacing = 8;

        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "▶";
            spotify = "";
          };
          status-icons = {
            paused = "⏸";
          };
          dynamic-len = 35;
        };

        privacy = {
          icon-size = 14;
          icon-spacing = 4;
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
        };

        "power-profiles-daemon" = {
          format = "{icon}";
          format-icons = {
            default = "󰗑";
            performance = "󱐋";
            balanced = "󰗑";
            power-saver = "󰌪";
          };
          tooltip-format = "Power profile: {profile}";
        };

        disk = {
          format = "󰋊 {percentage_used}%";
          path = "/";
          interval = 30;
        };

        "systemd-failed-units" = {
          format = "✗ {nr_failed}";
          format-ok = "";
          hide-on-ok = true;
        };

        "hyprland/language" = {
          format = "󰌌 {short}";
        };

        "custom/weather" = {
          exec = "waybar-weather";
          return-type = "json";
          interval = 900;
          on-click = "waybar-weather-toggle";
        };

        "custom/public-ip" = {
          exec = "waybar-public-ip";
          return-type = "json";
          interval = 300;
          format = "󰩠 {}";
        };

        "custom/gpu" = {
          exec = "waybar-gpu";
          return-type = "json";
          interval = 3;
        };

        "custom/ha-fan" = {
          exec = "waybar-ha-fan";
          return-type = "json";
          interval = 30;
          on-click = "ha-toggle switch.s40lite_0_2";
        };

        "custom/ha-lamp" = {
          exec = "waybar-ha-lamp";
          return-type = "json";
          interval = 30;
          on-click = "ha-toggle switch.s40lite_0";
        };

        "custom/ha-office-fan" = {
          format = "󰐊";
          tooltip = false;
          on-click = "ha-run-script script.turn_on_office_fan_for_5m";
        };

        "custom/ha-motion" = {
          exec = "waybar-ha-motion";
          return-type = "json";
          interval = 30;
        };

        "custom/ha-cameras" = {
          format = "󰄀";
          tooltip = false;
          on-click = "ha-cameras";
        };

        "custom/timer" = {
          exec = "waybar-timer";
          return-type = "json";
          interval = 1;
          on-click = "timer-start";
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon}";
          format-icons = {
            notification = "󱅫";
            none = "󰂜";
            dnd-notification = "󱏨";
            dnd-none = "󰪑";
            inhibited-notification = "󱅫";
            inhibited-none = "󰂜";
            dnd-inhibited-notification = "󱏨";
            dnd-inhibited-none = "󰪑";
          };
          return-type = "json";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };

        "custom/power-menu" = {
          format = "⏻";
          tooltip = false;
          on-click = "waybar-power-menu";
        };

        "custom/color-picker" = {
          format = "󰈊";
          tooltip = false;
          on-click = "hyprpicker -a";
        };

        "custom/clipboard" = {
          format = "󰅍";
          tooltip = false;
          on-click = "waybar-clipboard";
        };
      };

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 13px;
          min-height: 0;
        }
        window#waybar {
          background: #1e1e2e;
          color: #cdd6f4;
        }
        #workspaces button {
          padding: 0 8px;
          color: #a6adc8;
          background: transparent;
        }
        #workspaces button.active {
          color: #1e1e2e;
          background: #b4befe;
          border-radius: 8px;
        }
        #cpu,
        #memory,
        #temperature,
        #pulseaudio,
        #bluetooth,
        #battery,
        #clock,
        #tray,
        #mpris,
        #disk,
        #privacy,
        #idle_inhibitor,
        #power-profiles-daemon,
        #systemd-failed-units,
        #language,
        #custom-weather,
        #custom-public-ip,
        #custom-gpu,
        #custom-ha-fan,
        #custom-ha-lamp,
        #custom-ha-office-fan,
        #custom-ha-motion,
        #custom-ha-cameras,
        #custom-timer,
        #custom-notification,
        #custom-power-menu,
        #custom-color-picker,
        #custom-clipboard {
          padding: 0 8px;
        }
        #cpu { color: #f38ba8; }
        #memory { color: #f9e2af; }
        #temperature { color: #fab387; }
        #pulseaudio { color: #94e2d5; }
        #bluetooth { color: #89dceb; }
        #bluetooth.disabled,
        #bluetooth.off { color: #6c7086; }
        #battery { color: #a6e3a1; }
        #custom-gpu { color: #cba6f7; }
        #custom-weather { color: #74c7ec; }
        #mpris { color: #cba6f7; }
        #disk { color: #f2cdcd; }
        #privacy { color: #f38ba8; }
        #idle_inhibitor.activated { color: #f9e2af; }
        #idle_inhibitor.deactivated { color: #6c7086; }
        #power-profiles-daemon { color: #a6e3a1; }
        #systemd-failed-units { color: #f38ba8; }
        #language { color: #b4befe; }
        #custom-clipboard { color: #cdd6f4; }
        #custom-color-picker { color: #f5c2e7; }
        #custom-power-menu { color: #f38ba8; }
        #clock { color: #cdd6f4; font-weight: bold; }
        #custom-ha-office-fan,
        #custom-ha-cameras { color: #89b4fa; }
        #custom-ha-fan.on,
        #custom-ha-lamp.on { color: #a6e3a1; }
        #custom-ha-fan.off,
        #custom-ha-lamp.off { color: #6c7086; }
        #custom-ha-fan.unavailable,
        #custom-ha-lamp.unavailable,
        #custom-ha-motion.unavailable { color: #45475a; }
        #custom-ha-motion.active,
        #custom-ha-motion.recent { color: #a6e3a1; }
        #custom-ha-motion.idle { color: #cdd6f4; }
        #custom-ha-motion.stale { color: #6c7086; }
        #custom-timer.running { color: #f9e2af; }
        #custom-timer.idle { color: #cdd6f4; }
        #temperature.critical,
        #battery.critical { color: #f38ba8; }
      '';
    };
  };
}
