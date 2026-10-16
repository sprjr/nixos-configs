{ config, pkgs, ... }:

{
  # dauntless resolves over MagicDNS, which is not up during early boot; retry on access.
  fileSystems."/mnt/unraid/Gitea" = {
    device = "dauntless:/mnt/user/Gitea";
    fsType = "nfs";
    options = [
      "nofail"
      "sync"
      "noatime"
      "_netdev"
      "timeo=50"
      "retrans=2"
      "actimeo=5"
      "x-systemd.automount"
      "x-systemd.after=tailscaled.service"
    ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
