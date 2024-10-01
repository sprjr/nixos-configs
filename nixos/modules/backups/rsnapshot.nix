{ config, pkgs, ... }:

let
  chown_script = pkgs.writeShellScriptBin "chown-rsnapshot" ''
    #!/usr/bin/env bash
    chown -R root:backups /media/backups
    chmod -R g+r /media/backups
  '';
in {
  # Create backup user and group
  users = {
    groups = {
      backups {};
    };
    users.backups = {
      createHome = true;
      isNormalUser = true;
      description = "backups";
      group = "backups";
      home = "/home/backups";
      shell = "${pkgs.bash}/bin/bash";
      openssh.authorizedKeys.keys [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+K/JUb6pVsBbu4FmLJa/Yzgfn4S5kLoFSXJUUcVyl4 root@seanix"
      ];
    };
  };

  # Macs??

  services.rsnapshot = {
    enable = true;
    enableManualRsnapshot = true;
    cronIntervals = {
      hourly = "0 * * * *";
      daily = "30 3 * * *";
      weekly = "0 2 * * 0";
      monthly = "0 2 1 * *";
    };
    extraConfig = ''
# Separate everything with tabs, not spaces.
# to convert to tabs in Vim, use :%s/\s\+/\t/g
logfile	/media/backups/log/rsnapshot-trixos.log
snapshot_root	/media/backups/
retain	hourly	24
retain	daily	7
retain	weekly	4
retain	monthly	6

# wopr
backup	root@wopr:/media/books	media/books
backup	root@wopr:/media/audiobooks	media/books
backup	root@wopr:/home/sean/core/minecraft	gaming/minecraft
backup	root@wopr:/home/sean/.backups/	wopr
backup	root@wopr:/home/sean/core/plex/tautulli/data/backups	wopr/containers/tautulli
backup	root@wopr:/home/sean/core/plex/radarr-lscr/data/Backups/scheduled	wopr/containers/radarr
backup	root@wopr:/home/sean/core/plex/sonarr-lscr/data/Backups/scheduled	wopr/containers/sonarr
backup	root@wopr:/home/sean/core/plex/readarr/data/Backups/scheduled	wopr/containers/readarr
backup	root@wopr:/home/sean/core/plex/plex-lscr	wopr/containers/plex
backup	root@wopr:/home/sean/core/plex/wizarr	wopr/containers/wizarr
backup	root@wopr:/home/sean/core/plex/kavita	wopr/containers/kavita
backup	root@wopr:/home/sean/core/audiobookshelf	wopr/containers/audiobookshelf
backup	root@wopr:/home/sean/core/caddy	wopr/containers/caddy

# macnnix
backup	root@macnnix:/etc/nixos/	/nixos/macnnix/config

cmd_postexec	${chown_script}/bin/chown-rsnapshot
    '';
  };
}
