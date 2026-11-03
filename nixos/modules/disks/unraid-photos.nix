{ config, pkgs, ... }:

{
  # dauntless resolves over VPN DNS, which is not up during early boot; retry on access.
  fileSystems."/mnt/unraid/Photos" = {
    device = "dauntless:/mnt/user/Photos";
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
