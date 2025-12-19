{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Nextcloud" = {
    device = "dauntless:/mnt/user/Nextcloud";
    fsType = "nfs";
    options = [ "nofail" "defaults" ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
