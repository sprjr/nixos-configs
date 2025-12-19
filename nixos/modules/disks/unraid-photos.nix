{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Photos" = {
    device = "dauntless:/mnt/user/Photos";
    fsType = "nfs";
    options = [ "nofail" "defaults" ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
