{ config, pkgs, ... }:

let
  backupDir = "/.snapshots/hermes-agent";
  sourceDir = "/var/lib/hermes-agent";
  retainDays = 14;

  backupScript = pkgs.writeScript "hermes-backup.sh" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    timestamp=$(date +%Y%m%d-%H%M%S)
    dest="${backupDir}/$timestamp"

    mkdir -p "$dest"
    ${pkgs.rsync}/bin/rsync -a --delete "${sourceDir}/" "$dest/"

    # Prune snapshots older than ${toString retainDays} days
    find "${backupDir}" -maxdepth 1 -mindepth 1 -type d -mtime +${toString retainDays} -exec rm -rf {} +
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${backupDir} 0700 root root -"
  ];

  systemd.services.hermes-backup = {
    description = "Backup hermes-agent data directory";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = backupScript;
    };
    path = [ pkgs.coreutils pkgs.findutils ];
  };

  systemd.timers.hermes-backup = {
    description = "Daily backup of hermes-agent data";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
