{ pkgs, lib, ... }:

{
  # 1TB Samsung 860 m.2
  fileSystems."/mnt/media/samsung_ssd_860" = {
    device = "/dev/disk/a1722424-cc15-479d-94d2-b15c238cdb03";
    fsType = "ext4";
  };
}
