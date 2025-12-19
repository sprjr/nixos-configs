{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Workstations" = {
    device = "dauntless:/mnt/user/Workstations";
    fsType = "nfs";
    options = [ "nofail" "defaults" ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
