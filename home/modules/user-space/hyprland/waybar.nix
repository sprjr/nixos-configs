{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.patrick.home.hyprland;
  c = config.lib.stylix.colors.withHashtag;

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

  dictLookup = pkgs.writeShellApplication {
    name = "dict-lookup";
    runtimeInputs = with pkgs; [
      wordnet
      fuzzel
      libnotify
      wl-clipboard
    ];
    text = ''
      if [ "''${1:-}" = "--selection" ]; then
        word=$(wl-paste --primary 2>/dev/null || wl-paste 2>/dev/null || true)
      else
        word="''${1:-}"
      fi
      if [ -z "$word" ]; then
        word=$(fuzzel --dmenu --prompt "Define  " || true)
      fi
      if [ -z "$word" ]; then
        exit 0
      fi
      result=$(wn "$word" -over 2>&1 || true)
      if [ -z "$result" ]; then
        notify-send -t 5000 "Dictionary" "No definition found for: $word"
      else
        notify-send -t 0 "Dictionary: $word" "$result"
      fi
    '';
  };

  jpLookup = pkgs.writeShellApplication {
    name = "jp-lookup";
    runtimeInputs = with pkgs; [
      curl
      jq
      fuzzel
      libnotify
      wl-clipboard
    ];
    text = ''
      if [ "''${1:-}" = "--selection" ]; then
        word=$(wl-paste --primary 2>/dev/null || wl-paste 2>/dev/null || true)
      else
        word="''${1:-}"
      fi
      if [ -z "$word" ]; then
        word=$(fuzzel --dmenu --prompt "日本語  " || true)
      fi
      if [ -z "$word" ]; then
        exit 0
      fi
      encoded=$(printf '%s' "$word" | jq -sRr @uri)
      response=$(curl -sf "https://jisho.org/api/v1/search/words?keyword=$encoded" || true)
      if [ -z "$response" ]; then
        notify-send -t 5000 "Jisho" "Network error looking up: $word"
        exit 1
      fi
      result=$(printf '%s' "$response" | jq -r '
        .data[0:3][] |
        "【\(.japanese[0].word // .japanese[0].reading // "?")】\(.japanese[0].reading // "")\n" +
        (.senses[0:2][] | "  • \(.english_definitions | join(", "))")
      ' 2>/dev/null || true)
      if [ -z "$result" ]; then
        notify-send -t 5000 "Jisho" "No results for: $word"
      else
        notify-send -t 0 "Jisho: $word" "$(printf '%b' "$result")"
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

  modulesLeft = [
    "hyprland/workspaces"
  ]
  ++ haModules
  ++ [
    "custom/timer"
    "custom/weather"
    "custom/calendar"
    "custom/public-ip"
  ];

  # Modules that appear/disappear or change item count sit at the outer (left) edge so
  # toggling them never shifts the fixed-width modules to their right.
  modulesRight = [
    "privacy"
    "systemd-failed-units"
    "tray"
    "custom/budslink"
    "network"
    "pulseaudio"
    "bluetooth"
    #"cpu"
    #"memory"
    #"disk"
    #"temperature"
  ]
  ++ [
    "custom/hwmon"
    "power-profiles-daemon"
  ]
  ++ optional cfg.battery "battery"
  ++ [
    "hyprland/language"
    "idle_inhibitor"
    "custom/keybinds"
    "custom/app-launcher"
    "custom/dict"
    "custom/jp-dict"
    "custom/clipboard"
    "custom/color-picker"
    "custom/screenshot"
    "custom/notification"
    "custom/control-center"
  ]
  ++ cfg.waybarExtra;
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    home.packages = [
      pkgs.blueman
      pkgs.cliphist
      pkgs.hyprpicker
      btToggle
      clipboardBrowse
      dictLookup
      jpLookup
    ];

    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        targets = [ "hyprland-session.target" ];
      };
      style = ''
        * {
          min-height: 0;
          /* Tabular digits so changing numbers don't change label width. */
          font-feature-settings: "tnum";
        }
        /* Reserve each variable-content module's widest state (tune to font size). */
        #custom-timer,
        #custom-weather { min-width: 56px; }
        #custom-ha-motion { min-width: 48px; }
        #custom-hwmon { min-width: 88px; }
        #workspaces button {
          padding: 0 8px;
          color: ${c.base04};
          background: transparent;
        }
        #workspaces button.active {
          color: ${c.base00};
          background: ${c.base07};
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
        #mpris,
        #disk,
        #privacy,
        #idle_inhibitor,
        #power-profiles-daemon,
        #systemd-failed-units,
        #language,
        #custom-weather,
        #custom-calendar,
        #custom-public-ip,
        #custom-hwmon,
        #custom-budslink,
        #custom-ha-fan,
        #custom-ha-lamp,
        #custom-ha-office-fan,
        #custom-ha-motion,
        #custom-ha-cameras,
        #custom-timer,
        #custom-notification,
        #custom-app-launcher,
        #custom-dict,
        #custom-jp-dict,
        #custom-color-picker,
        #custom-clipboard,
        #custom-screenshot,
        #custom-control-center,
        #custom-keybinds {
          padding: 0 8px;
        }
        #cpu { color: ${c.base08}; }
        #memory { color: ${c.base0A}; }
        #temperature { color: ${c.base09}; }
        #network { color: ${c.base0D}; }
        #network.disconnected { color: ${c.base04}; }
        #pulseaudio { color: ${c.base0C}; }
        #bluetooth { color: ${c.base0D}; }
        #bluetooth.disabled,
        #bluetooth.off { color: ${c.base04}; }
        #battery { color: ${c.base0B}; }
        #custom-hwmon { color: ${c.base0E}; }
        #custom-hwmon.warning { color: ${c.base0A}; }
        #custom-hwmon.critical { color: ${c.base08}; }
        #custom-weather { color: ${c.base0D}; }
        #custom-calendar { color: ${c.base0C}; }
        #custom-budslink { color: ${c.base0E}; }
        #mpris { color: ${c.base0E}; }
        #disk { color: ${c.base0F}; }
        #privacy { color: ${c.base08}; }
        #idle_inhibitor.activated { color: ${c.base0A}; }
        #idle_inhibitor.deactivated { color: ${c.base04}; }
        #power-profiles-daemon { color: ${c.base0B}; }
        #systemd-failed-units { color: ${c.base08}; }
        #language { color: ${c.base07}; }
        #custom-app-launcher { color: ${c.base07}; }
        #custom-dict { color: ${c.base05}; }
        #custom-jp-dict { color: ${c.base06}; }
        #custom-clipboard { color: ${c.base05}; }
        #custom-color-picker { color: ${c.base0F}; }
        #custom-screenshot { color: ${c.base05}; }
        #custom-notification { color: ${c.base05}; }
        #custom-control-center { color: ${c.base0D}; }
        #custom-keybinds { color: ${c.base0D}; }
        #clock { color: ${c.base05}; font-weight: bold; }
        #clock.tokyo { color: ${c.base04}; font-size: 11px; }
        #custom-ha-office-fan,
        #custom-ha-cameras { color: ${c.base0D}; }
        #custom-ha-fan.on,
        #custom-ha-lamp.on { color: ${c.base0B}; }
        #custom-ha-fan.off,
        #custom-ha-lamp.off { color: ${c.base04}; }
        #custom-ha-fan.unavailable,
        #custom-ha-lamp.unavailable,
        #custom-ha-motion.unavailable { color: ${c.base03}; }
        #custom-ha-motion.active,
        #custom-ha-motion.recent { color: ${c.base0B}; }
        #custom-ha-motion.idle { color: ${c.base05}; }
        #custom-ha-motion.stale { color: ${c.base04}; }
        #custom-timer.running { color: ${c.base0A}; }
        #custom-timer.idle { color: ${c.base05}; }
        #temperature.critical,
        #battery.critical { color: ${c.base08}; }
        #battery.warning { color: ${c.base0A}; }
      '';
      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 6;

        modules-left = modulesLeft;
        modules-center = [
          "mpris"
          "clock"
          "clock#tokyo"
        ];
        modules-right = modulesRight;

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{id}";
        };

        clock = {
          format = "{:%a %d %b  %H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };

        "clock#tokyo" = {
          format = "TYO {:%H:%M}";
          timezone = "Asia/Tokyo";
          tooltip-format = "Tokyo: {:%A %d %B %H:%M}";
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
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format-disconnected = "Disconnected";
          on-click = "control-center-toggle";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          # Keep the volume digits when muted so the module width doesn't collapse.
          format-muted = "󰝟 {volume}%";
          format-icons.default = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          on-click = "control-center-toggle";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        bluetooth = {
          format = "󰂯";
          format-connected = "󰂱 {num_connections}";
          format-disabled = "󰂲";
          format-off = "󰂲";
          tooltip-format = "{controller_alias}\n{status}";
          tooltip-format-connected = "{controller_alias}\n{device_enumerate}";
          on-click = "control-center-toggle";
          on-click-right = "bt-toggle";
          on-click-middle = "blueman-manager";
        };

        "custom/budslink" = {
          exec = "waybar-budslink";
          return-type = "json";
          interval = 30;
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          on-click = "control-center-toggle";
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
          start-activated = true;
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
          on-click = "control-center-toggle";
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

        "custom/calendar" = {
          exec = "waybar-calendar";
          return-type = "json";
          interval = 300;
        };

        "custom/public-ip" = {
          exec = "waybar-public-ip";
          return-type = "json";
          interval = 300;
          format = "󰩠 {}";
        };

        # Continuous exec: hwstat --bar emits a line every 2s.
        "custom/hwmon" = {
          exec = "hwstat --bar";
          return-type = "json";
          on-click = "hw-monitor-toggle";
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

        "custom/dict" = {
          format = "";
          tooltip = false;
          on-click = "dict-lookup";
        };

        "custom/jp-dict" = {
          format = "󰗊";
          tooltip = false;
          on-click = "jp-lookup";
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

        "custom/screenshot" = {
          format = "󰹑";
          tooltip = false;
          on-click = "grimblast copy area";
          on-click-right = "grimblast copy screen";
        };

        "custom/app-launcher" = {
          format = "󱓞";
          tooltip = false;
          on-click = "hyprctl dispatch exec fuzzel";
        };

        "custom/control-center" = {
          format = "󰒓";
          tooltip = false;
          on-click = "control-center-toggle";
        };

        "custom/keybinds" = {
          format = "󰌌";
          tooltip = false;
          on-click = "keybinds-toggle";
        };
      };
    };
  };
}
