{ config, pkgs, lib, ... }:

let
  waitForData = pkgs.writeShellScript "wait-for-nextcloud-data" ''
    for _ in $(${pkgs.coreutils}/bin/seq 1 24); do
      ${pkgs.coreutils}/bin/ls /var/lib/nextcloud/data >/dev/null 2>&1 || true
      if ${pkgs.gnugrep}/bin/grep -qs " /var/lib/nextcloud/data nfs" /proc/mounts; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 5
    done
    echo "/var/lib/nextcloud/data is not an nfs mount after 120s" >&2
    exit 1
  '';
in
{
  # Only Nextcloud's user-data directory lives on NFS; config stays local.
  # dauntless resolves over MagicDNS, which is not up during early boot; retry on access.
  fileSystems."/var/lib/nextcloud/data" = {
    device = "dauntless:/mnt/user/Nextcloud/data";
    fsType = "nfs";
    options = [
      "nofail"
      "defaults"
      "x-systemd.automount"
      "x-systemd.after=tailscaled.service"
    ];
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

  # RequiresMountsFor would pull the automount in eagerly at boot; wait on the mount instead.
  systemd.tmpfiles.rules = [ "d /var/lib/nextcloud 0750 nextcloud nextcloud - -" ];
  systemd.services = lib.mkIf config.services.nextcloud.enable {
    nextcloud-setup.serviceConfig.ExecStartPre = [ waitForData ];
    phpfpm-nextcloud.serviceConfig.ExecStartPre = [ waitForData ];
  };
}
