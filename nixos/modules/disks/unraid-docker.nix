{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Docker" = {
    device = "dauntless:/mnt/user/Docker";
    fsType = "nfs";
    options = [ "nofail" "defaults" ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
