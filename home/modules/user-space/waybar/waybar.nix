{ config, pkgs, lib, ... }:

let
  netUsage = pkgs.writeShellScriptBin "net-usage" ''
    #!/usr/bin/env bash
    DEV=$(ip route | awk '/default/ {print $5; exit}')

    RX1=$(cat /sys/class/net/$DEV/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$DEV/statistics/tx_bytes)
    sleep 1
    RX2=$(cat /sys/class/net/$DEV/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/$DEV/statistics/tx_bytes)

    RXBPS=$(( (RX2 - RX1) / 1024 / 1024 ))
    TXBPS=$(( (TX2 - TX1) / 1024 / 1024 ))

    echo "↓ ''${RXBPS}MB/s ↑ ''${TXBPS}MB/s"
  '';

  topNet = pkgs.writeShellScriptBin "top-net" ''
    #!/usr/bin/env bash
    # Requires nethogs with sudo NOPASSWD
    sudo -n ${pkgs.nethogs}/bin/nethogs -t -c 1 2>/dev/null \
      | awk 'NR==1 {print $1 " " $2 "KB/s"}'
  '';
in
{
  home.packages = with pkgs; [
    sysstat
    iproute2
    nethogs
    bandwhich
    netUsage
    topNet
  ];

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";

        modules-left = [
          "cpu"
          "memory"
          "custom/net"
          "custom/top-net"
        ];

        modules-right = [
          "clock"
          "tray"
        ];

        cpu = {
          format = " {usage}%";
        };

        memory = {
          format = " {used:0.1f}G/{total:0.1f}G";
        };

        "custom/net" = {
          exec = "net-usage";
          interval = 1;
          format = " {output}";
        };

        "custom/top-net" = {
          exec = "top-net";
          interval = 2;
          format = " {output}";
        };
      };
    };

    style = ''
      #cpu {
        color: #ff6e67;
      }
      #memory {
        color: #f9e79f;
      }
      #custom-net {
        color: #5dade2;
      }
      #custom-top-net {
        color: #58d68d;
      }
    '';
  };
}

