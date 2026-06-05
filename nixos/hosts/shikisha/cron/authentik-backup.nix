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
      path = [ pkgs.docker ];
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
