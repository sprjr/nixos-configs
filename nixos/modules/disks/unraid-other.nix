{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Other" = {
    device = "dauntless:/mnt/user/Other";
    fsType = "nfs";
    options = [ "nofail" "defaults" ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
