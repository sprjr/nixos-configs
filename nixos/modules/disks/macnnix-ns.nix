{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/media/share" = {
    device = "//100.117.100.77/mnt/backups/sda1";
    fsType = "cifs";
    options = let
      # This line prevents hanging on a network split
      automount_opts = "x-systemd.automount,noaudo,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in ["${automount_opts},credentials=/etc/nixos/smb-secrets"];
  };
}
