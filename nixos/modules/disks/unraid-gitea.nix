{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Gitea" = {
    device = "dauntless:/mnt/user/Gitea";
    fsType = "nfs";
    options = [ "nofail" "defaults" ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
