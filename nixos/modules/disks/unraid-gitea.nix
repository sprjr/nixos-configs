{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Gitea" = {
    device = "dauntless:/mnt/user/Gitea";
    fsType = "nfs";
    options = [ "nofail" "sync" "noatime" "_netdev" "timeo=50" "retrans=2" "actimeo=5" ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
