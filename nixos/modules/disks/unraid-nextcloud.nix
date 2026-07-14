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
  # `stat`s to a different UID. The group is set to the same value the
  # nextcloud service module uses, so this stays valid even if that module
  # is disabled (avoids the "group is unset" assertion).
  users.users.nextcloud = {
    uid = 99;
    group = "nextcloud";
  };
  users.groups.nextcloud = { };

  # Ensure the local parent exists before the NFS mount, and that
  # nextcloud-setup waits for the data mount.
  systemd.tmpfiles.rules = [ "d /var/lib/nextcloud 0750 nextcloud nextcloud - -" ];
  systemd.services = lib.mkIf config.services.nextcloud.enable {
    nextcloud-setup.unitConfig.RequiresMountsFor = [ "/var/lib/nextcloud/data" ];
    phpfpm-nextcloud.unitConfig.RequiresMountsFor = [ "/var/lib/nextcloud/data" ];
  };
}
