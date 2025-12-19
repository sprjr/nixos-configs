{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Kubernetes" = {
    device = "dauntless:/mnt/user/Kubernetes";
    fsType = "nfs";
    options = [ "nofail" "defaults" ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
