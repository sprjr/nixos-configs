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
# Catppuccin Mocha styling. Launched via exec-once in default.nix (no systemd unit).
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
      "hyprland/window"
    ];

  modulesRight =
    [
      "custom/weather"
      "network"
      "custom/private-ip"
      "custom/public-ip"
      "pulseaudio"
      "bluetooth"
      "cpu"
      "memory"
      "temperature"
    ]
    ++ optional (cfg.gpu != null) "custom/gpu"
    ++ optional cfg.battery "battery"
    ++ [
      "tray"
      "custom/notification"
      "clock"
    ]
    ++ cfg.waybarExtra;
in
{
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.blueman
      btToggle
    ];

    programs.waybar = {
      enable = true;
      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 6;

        modules-left = modulesLeft;
        modules-center = [ "clock" ];
        modules-right = modulesRight;

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{id}";
        };

        "hyprland/window" = {
          max-length = 60;
          separate-outputs = true;
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

        network = {
          format-wifi = " {essid}";
          format-ethernet = "󰈀 {ifname}";
          format-disconnected = "󰤭";
          tooltip-format = "{ipaddr}/{cidr}";
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

        "custom/weather" = {
          exec = "waybar-weather";
          return-type = "json";
          interval = 900;
        };

        "custom/public-ip" = {
          exec = "waybar-public-ip";
          return-type = "json";
          interval = 300;
          format = "󰩠 {}";
        };

        "custom/private-ip" = {
          exec = "waybar-private-ip";
          return-type = "json";
          interval = 30;
          format = "󰛳 {}";
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
        #network,
        #pulseaudio,
        #bluetooth,
        #battery,
        #clock,
        #tray,
        #window,
        #custom-weather,
        #custom-public-ip,
        #custom-private-ip,
        #custom-gpu,
        #custom-ha-fan,
        #custom-ha-lamp,
        #custom-ha-office-fan,
        #custom-ha-motion,
        #custom-ha-cameras,
        #custom-timer,
        #custom-notification {
          padding: 0 8px;
        }
        #cpu { color: #f38ba8; }
        #memory { color: #f9e2af; }
        #temperature { color: #fab387; }
        #network { color: #89b4fa; }
        #pulseaudio { color: #94e2d5; }
        #bluetooth { color: #89dceb; }
        #bluetooth.disabled,
        #bluetooth.off { color: #6c7086; }
        #battery { color: #a6e3a1; }
        #custom-gpu { color: #cba6f7; }
        #custom-weather { color: #74c7ec; }
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
