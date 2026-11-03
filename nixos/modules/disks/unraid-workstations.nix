{ config, pkgs, ... }:

{
  # dauntless resolves over VPN DNS, which is not up during early boot; retry on access.
  fileSystems."/mnt/unraid/Workstations" = {
    device = "dauntless:/mnt/user/Workstations";
    fsType = "nfs";
    options = [
      "nofail"
      "defaults"
      "x-systemd.automount"
      "x-systemd.after=tailscaled.service"
      "x-systemd.after=netbird-default.service"
    ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
