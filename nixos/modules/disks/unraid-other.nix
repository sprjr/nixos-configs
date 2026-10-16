{ config, pkgs, ... }:

{
  # dauntless resolves over MagicDNS, which is not up during early boot; retry on access.
  fileSystems."/mnt/unraid/Other" = {
    device = "dauntless:/mnt/user/Other";
    fsType = "nfs";
    options = [
      "nofail"
      "defaults"
      "x-systemd.automount"
      "x-systemd.after=tailscaled.service"
    ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
