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

  # LUKS2 data disks, unlocked in stage 2 via TPM2; see docs/GUIDE-seanix-data-disks.md
  environment.etc."crypttab".text = ''
    data-fast PARTLABEL=data-fast - tpm2-device=auto,nofail
    data-bulk PARTLABEL=data-bulk - tpm2-device=auto,nofail
  '';

  fileSystems."/mnt/fast" = {
    device = "/dev/mapper/data-fast";
    fsType = "ext4";
    options = [ "nofail" "noatime" "x-systemd.device-timeout=10s" ];
  };

  fileSystems."/mnt/bulk" = {
    device = "/dev/mapper/data-bulk";
    fsType = "ext4";
    options = [ "nofail" "noatime" "x-systemd.device-timeout=10s" ];
  };

  # Ensure the mount point directory exists
  systemd.tmpfiles.rules = [
    "d /mnt/media/data 0755 root root - -"
  ];

  # Also add this to ensure the mount works
  boot.supportedFilesystems = [ "ext4" ];
}
