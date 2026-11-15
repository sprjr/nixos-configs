{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab.kiwix-server;
  dataDir = cfg.dataDir;
  zimFile = cfg.zimFile;
  port = cfg.port;
  lockFile = "${dataDir}/.download.lock";

  downloadScript = pkgs.writeShellApplication {
    name = "kiwix-download";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.findutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.util-linux
      pkgs.zim-tools
    ];
    text = ''
      urls_file="${toString zimFile}"
      dest_root="${dataDir}"
      lock_file="${lockFile}"
      failed=0

      exec 200>"$lock_file"
      if ! flock -n 200; then
        echo "Another kiwix-download is already running; exiting"
        exit 0
      fi

      remote_size() {
        local url="$1"
        local total
        total=$(curl -fsSL -D - -o /dev/null -r 0-0 --retry 3 --connect-timeout 30 --max-time 60 "$url" | tr -d '\r' | awk 'tolower($1)=="content-range:" {split($3,a,"/"); t=a[2]} tolower($1)=="content-length:" && t=="" {size=$2} END { if (t!="") print t; else print size }')
        printf '%s' "$total"
      }

      is_dated_zim() {
        case "$1" in
          [0-9][0-9][0-9][0-9]-[0-9][0-9].zim | [0-9][0-9][0-9][0-9]-[0-9][0-9][a-z].zim) return 0 ;;
          *) return 1 ;;
        esac
      }

      prune_superseded() {
        local dir="$1"
        local name="$2"
        local stem="''${name%_*}"
        local old suffix
        for old in "''${dir}/''${stem}_"*.zim; do
          [ -e "$old" ] || continue
          [ "$old" = "''${dir}/$name" ] && continue
          suffix="''${old##*/}"
          suffix="''${suffix#"''${stem}"_}"
          if is_dated_zim "$suffix"; then
            echo "Removing superseded $old"
            rm -f "$old"
          fi
        done
      }

      umask 022
      mkdir -p "$dest_root"

      while read -r category url _; do
        case "$category" in
          "" | "#"*) continue ;;
        esac
        [ -n "$url" ] || continue

        name="''${url##*/}"
        dir="''${dest_root}/$category"
        dest="$dir/$name"
        part="$dest.part"
        mkdir -p "$dir"

        size=$(remote_size "$url")
        if [ -z "$size" ]; then
          echo "ERROR: could not determine size of $url"
          failed=$((failed + 1))
          continue
        fi

        if [ -f "$dest" ] && [ "$(wc -c < "$dest")" = "$size" ]; then
          echo "Up to date: $category/$name"
          prune_superseded "$dir" "$name"
          continue
        fi

        if [ -f "$part" ] && [ "$(wc -c < "$part")" -gt "$size" ]; then
          rm -f "$part"
        fi

        echo "Downloading $category/$name ($size bytes)"
        if curl -fL --no-progress-meter --show-error --retry 5 --retry-delay 15 --connect-timeout 30 --speed-limit 1024 --speed-time 120 -C - -o "$part" "$url"; then
          actual=$(wc -c < "$part")
          if [ "$actual" != "$size" ]; then
            echo "ERROR: size mismatch for $category/$name ($actual != $size)"
            failed=$((failed + 1))
            continue
          fi
          if ! zimcheck -i "$part"; then
            echo "ERROR: zimcheck failed for $category/$name"
            failed=$((failed + 1))
            rm -f "$part"
            continue
          fi
          mv -f "$part" "$dest"
          prune_superseded "$dir" "$name"
        else
          echo "ERROR: failed to download $url"
          failed=$((failed + 1))
        fi
      done < "$urls_file"

      if [ "$failed" -gt 0 ]; then
        echo "$failed download(s) failed"
        exit 1
      fi
      echo "All ZIM files are up to date"
    '';
  };
in
{
  options.homelab.kiwix-server = {
    enable = lib.mkEnableOption "Kiwix ZIM server";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/unraid/Other/kiwix";
      description = "Directory where ZIM files are stored and served from.";
    };
    zimFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../data/kiwix-zims.txt;
      description = "Path to the file listing ZIM categories and URLs.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8085;
      description = "Port for the Kiwix HTTP server.";
    };
    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "Sun 03:00";
      description = "Systemd OnCalendar expression for the ZIM download timer.";
    };
    packageUser = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User that runs the download service.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.kiwix-download = {
      description = "Download Kiwix ZIM files";
      after = [ "network-online.target" "tailscaled.service" "netbird-default.service" "mnt-unraid-Other.mount" ];
      wants = [ "network-online.target" "tailscaled.service" "netbird-default.service" ];
      # Fail rather than makedirs into the empty automount point if the NFS share
      # is not up yet; touching the path is what triggers the automount.
      serviceConfig = {
        Type = "oneshot";
        User = cfg.packageUser;
        ExecStart = "${downloadScript}/bin/kiwix-download";
        ExecStartPre = [
          (pkgs.writeShellScript "require-unraid-other" ''
            for _ in $(seq 1 24); do
              ls "/mnt/unraid/Other" >/dev/null 2>&1 || true
              if grep -qs " /mnt/unraid/Other nfs" /proc/mounts; then
                exit 0
              fi
              sleep 5
            done
            echo "/mnt/unraid/Other is not an nfs mount after 120s" >&2
            exit 1
          '')
        ];
        Nice = 19;
        IOSchedulingClass = "idle";
        RequiresMountsFor = [ dataDir ];
      };
    };

    systemd.timers.kiwix-download = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "10m";
        Unit = "kiwix-download.service";
      };
    };

    systemd.services.kiwix-http = {
      description = "Kiwix ZIM HTTP server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "mnt-unraid-Other.mount" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd ${dataDir} --port ${toString port} --addr 0.0.0.0 --no-listing";
        Restart = "always";
        RequiresMountsFor = [ dataDir ];
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
    networking.firewall.interfaces.netbird0.allowedTCPPorts = [ port ];
  };
}
