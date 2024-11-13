{ pkgs, lib, ... }:

{
  # 1TB Samsung 860 m.2
  fileSystems."/mnt/media/6655e2e3-ce9e-42eb-8043-6a553ced1d76" = {
    device = "/dev/disk/by-uuid/b6655e2e3-ce9e-42eb-8043-6a553ced1d76";
    fsType = "ext4";
    options = [
      "nofail" # prevent system from failing if the drive doesn't mount
      "noatime"
      "defaults"
    ];
  };
}
