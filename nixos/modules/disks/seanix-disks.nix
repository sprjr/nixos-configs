{ pkgs, lib, ... }:

{
  # 1TB Samsung 860 m.2
  fileSystems."/mnt/media/drive-0" = {
    device = "/dev/disk/by-uuid/6655e2e3-ce9e-42eb-8043-6a553ced1d76";
    fsType = "ext4";
    options = [
      "nofail" # prevent system from failing if the drive doesn't mount
      "noatime"
      "defaults"
    ];
  };

  # Ensure mount point directory exists:
  systemd.tmpfiles.rules = [
    "d /mnt/media/drive-0 0755 root root - -"
  ];
}
