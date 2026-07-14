{ config, pkgs, lib, ... }:

{
  # Only Nextcloud's user-data directory lives on NFS; config stays local.
  fileSystems."/var/lib/nextcloud/data" = {
    device = "dauntless:/mnt/user/Nextcloud/data";
    fsType = "nfs";
    options = [ "nofail" "defaults" ];
  };
  boot.supportedFilesystems = [ "nfs" ];

  # Match the local nextcloud UID to the unraid export owner so NFS files
  # appear owned by nextcloud. 99 = unraid `nobody`; adjust if the share
  # `stat`s to a different UID.
  users.users.nextcloud.uid = 99;

  # Ensure the local parent exists before the NFS mount, and that
  # nextcloud-setup waits for the data mount.
  systemd.tmpfiles.rules = [ "d /var/lib/nextcloud 0750 nextcloud nextcloud - -" ];
  systemd.services.nextcloud-setup.unitConfig.RequiresMountsFor = [ "/var/lib/nextcloud/data" ];
  systemd.services.phpfpm-nextcloud.unitConfig.RequiresMountsFor = [ "/var/lib/nextcloud/data" ];
}
