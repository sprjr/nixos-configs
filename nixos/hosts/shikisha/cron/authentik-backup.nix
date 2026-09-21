{ config, pkgs, lib, ... }:

{
  systemd = {
    timers."authentik-backup" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Sun *-*-* 22:00:00 UTC";
        Persistent = "true";
        Unit = "authentik-backup.service";
      };
    };
    services."authentik-backup" = {
      path = [ pkgs.docker pkgs.gnugrep pkgs.coreutils ];
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
      # Fail rather than mkdir into the empty automount point if the NFS share
      # is not up yet; touching the path is what triggers the automount.
      serviceConfig.ExecStartPre = [
        (pkgs.writeShellScript "require-unraid-nextcloud" ''
          for _ in $(seq 1 24); do
            ls "/mnt/unraid/Nextcloud/data" >/dev/null 2>&1 || true
            if grep -qs " /mnt/unraid/Nextcloud/data nfs" /proc/mounts; then
              exit 0
            fi
            sleep 5
          done
          echo "/mnt/unraid/Nextcloud/data is not an nfs mount after 120s" >&2
          exit 1
        '')
      ];
      script = ''
        set -eu
        BACKUP_DIR="/home/patrick/.docker/authentik/db_backups"
        DEST_DIR="/mnt/unraid/Nextcloud/data/patrick/files/Tech/Backups/Authentik (monthly)"
        FILENAME="$(date +%Y-%m-%d)-authentik-postgres-backup.sql"

        mkdir -p "$BACKUP_DIR"
        mkdir -p "$DEST_DIR"

        docker exec -i authentik-postgresql-1 /usr/local/bin/pg_dump \
          --username authentik authentik > "$BACKUP_DIR/$FILENAME"

        cp "$BACKUP_DIR/$FILENAME" "$DEST_DIR/"
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
