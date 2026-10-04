{ pkgs, ... }:

let
  backupDir = "/.snapshots/hermes-agent";
  sourceDir = "/var/lib/hermes-agent";
  retain = 14;
  minFreeGiB = 40;

  excludes = [
    "--exclude=/tmp/"
    "--exclude=/.cache/"
    "--exclude=/.venvs/"
    "--exclude=/ocr-venv/"
    "--exclude=/lazy-packages/"
    "--exclude=/backups/"
    "--exclude=/home/.cache/"
    "--exclude=/home/.nix-portable/"
    "--exclude=/home/.local/share/nix/root/"
  ];

  backupScript = pkgs.writeShellApplication {
    name = "hermes-backup";
    runtimeInputs = with pkgs; [ rsync coreutils findutils gawk ];
    text = ''
      backupDir=${backupDir}
      retain=${toString retain}
      minFreeGiB=${toString minFreeGiB}
      minFree=$(( minFreeGiB * 1024 * 1024 * 1024 ))
      stamp="$(date +%Y%m%d-%H%M%S)"
      partial="$backupDir/.partial"
      dest="$backupDir/$stamp"

      mkdir -p "$backupDir"
      rm -rf -- "$partial"

      free_bytes() { df -PB1 "$backupDir" | awk 'NR==2 {print $4}'; }

      snapshots() {
        find "$backupDir" -maxdepth 1 -mindepth 1 -type d -name '20*' -printf '%f\n' 2>/dev/null | sort
      }

      # make room before starting, oldest first, but never drop the last snapshot
      while [ "$(free_bytes)" -lt "$minFree" ] && [ "$(snapshots | wc -l)" -gt 1 ]; do
        oldest="$(snapshots | head -1)"
        echo "hermes-backup: low free space, pruning $oldest"
        rm -rf -- "$backupDir/''${oldest:?}"
      done

      if [ "$(free_bytes)" -lt "$minFree" ]; then
        echo "hermes-backup: still below ''${minFreeGiB}GiB free after pruning; aborting" >&2
        exit 1
      fi

      prev="$(snapshots | tail -1)"
      linkArgs=()
      if [ -n "$prev" ]; then linkArgs=(--link-dest="$backupDir/$prev"); fi

      rsync -aH --delete --numeric-ids ${pkgs.lib.concatStringsSep " " excludes} \
        "''${linkArgs[@]}" "${sourceDir}/" "$partial/"

      mv -T -- "$partial" "$dest"

      mapfile -t snaps < <(snapshots)
      excess=$(( ''${#snaps[@]} - retain ))
      if [ "$excess" -gt 0 ]; then
        for old in "''${snaps[@]:0:excess}"; do
          echo "hermes-backup: pruning $old"
          rm -rf -- "$backupDir/''${old:?}"
        done
      fi

      echo "hermes-backup: $dest complete"
    '';
  };
in {
  systemd.services.hermes-backup = {
    description = "Snapshot /var/lib/hermes-agent into /.snapshots/hermes-agent";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${backupScript}/bin/hermes-backup";
      TimeoutStartSec = "1h";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.hermes-backup = {
    description = "Daily hermes-agent snapshot";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
