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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYxyYpBB8K35/1+c22hBDV6mQFkqvxJeBC/SWs8Yyh+ patrick@macnnix"
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

backup	root@wopr:/media/books	wopr