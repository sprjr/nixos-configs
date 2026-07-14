{ config, pkgs, ... }:

{
  fileSystems."/mnt/unraid/Media" = {
    device = "dauntless:/mnt/user/Media";
    fsType = "nfs";
    options = [
      "nofail"
      "defaults"
    ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
