{ config, pkgs, ... }:
{
  # GNOME as an available session (display manager handled by host)
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;

  # Kiosk Mode for GCompris
  services.cage = {
    enable = true;
    program = "${pkgs.gcompris}/bin/gcompris";
    user = "kiosk";
  };
  systemd.services."cage-tty1".after = [
    "network-online.target"
    "systemd-resolved.service"
  ];

  # Kiosk user for cage
  users.users.kiosk = {
    isNormalUser = true;
    group = "kiosk";
    hashedPassword = "!";
  };
  users.groups.kiosk = {};

  environment.systemPackages = with pkgs; [
    gcompris
  ];
}
