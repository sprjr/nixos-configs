{ pkgs, lib, ... }:

{
  systemd.mounts = [{
    what = "/dev/disk/by-uuid/6655e2e3-ce9e-42eb-8043-6a553ced1d76";
    where = "/mnt/media/data";
    type = "ext4";
    options = "defaults,nofail,noatime";
    wantedBy = [ "multi-user.target" ];
    enable = true;
  }];

  # Ensure the mount point directory exists
  systemd.tmpfiles.rules = [
    "d /mnt/media/data 0755 root root - -"
  ];

  # Also add this to ensure the mount works
  boot.supportedFilesystems = [ "ext4" ];
}
