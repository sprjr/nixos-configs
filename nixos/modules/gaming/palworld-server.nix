{ config, pkgs, lib, ... }:

let
  stateDir = "/var/lib/palworld";
  serverDir = "${stateDir}/server";
  configDir = "${serverDir}/Pal/Saved/Config/LinuxServer";

  palworld-fhs = pkgs.buildFHSEnv {
    name = "palworld-fhs";
    targetPkgs = pkgs: with pkgs; [
      glibc
      gcc-unwrapped.lib
      stdenv.cc.cc.lib
      libgcc
      zlib
      SDL2
      libx11
      libxcursor
      libxext
      libxi
      libxrandr
      libxrender
      libxfixes
      libxscrnsaver
      libxau
      steamcmd
    ];
    runScript = "";
  };

  steamcmdInstall = pkgs.writeShellScript "palworld-install" ''
    set -euo pipefail
    ${palworld-fhs}/bin/palworld-fhs \
      ${pkgs.steamcmd}/bin/steamcmd \
        +force_install_dir ${serverDir} \
        +login anonymous \
        +app_update 2394010 validate \
        +quit
  '';

  palworldLaunch = pkgs.writeShellScript "palworld-launch" ''
    set -euo pipefail
    cd ${serverDir}
    ${palworld-fhs}/bin/palworld-fhs ./PalServer.sh \
      -port=8211 \
      -players=32 \
      -logformat=text
  '';
in
{
  sops.secrets."palworld/admin-password" = {
    owner = "palworld";
    mode = "0400";
  };
  sops.secrets."palworld/server-password" = {
    owner = "palworld";
    mode = "0400";
  };

  sops.templates."palworld-settings.ini" = {
    owner = "palworld";
    mode = "0600";
    content = ''
      [/Script/Pal.PalGameWorldSettings]
      OptionSettings=(ServerName="Palworld Server",ServerPlayerMaxNum=32,AdminPassword="${config.sops.placeholder."palworld/admin-password"}",ServerPassword="${config.sops.placeholder."palworld/server-password"}",PublicPort=8211,RCONEnabled=False,RESTAPIEnabled=False)
    '';
  };

  users.users.palworld = {
    isSystemUser = true;
    group = "palworld";
    home = stateDir;
  };
  users.groups.palworld = {};

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 palworld palworld -"
    "d ${serverDir} 0750 palworld palworld -"
  ];

  systemd.services.palworld-install = {
    description = "Install/update Palworld via SteamCMD";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "palworld";
      Group = "palworld";
      WorkingDirectory = stateDir;
      ExecStart = steamcmdInstall;
      TimeoutStartSec = "30min";
    };
  };

  systemd.services.palworld-config = {
    description = "Deploy Palworld configuration";
    after = [ "palworld-install.service" ];
    requires = [ "palworld-install.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "palworld";
      Group = "palworld";
      ExecStart = pkgs.writeShellScript "palworld-deploy-config" ''
        set -euo pipefail
        mkdir -p ${configDir}
        cp -f ${config.sops.templates."palworld-settings.ini".path} \
              ${configDir}/PalWorldSettings.ini
        chmod 0600 ${configDir}/PalWorldSettings.ini
      '';
    };
  };

  systemd.services.palworld = {
    description = "Palworld Dedicated Server";
    after = [ "network.target" "palworld-config.service" ];
    requires = [ "palworld-config.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = palworldLaunch;
      Restart = "on-failure";
      RestartSec = "30s";
      User = "palworld";
      Group = "palworld";
      WorkingDirectory = serverDir;
      LimitNOFILE = 65536;
    };
  };

  systemd.services.palworld-update = {
    description = "Update Palworld server";
    conflicts = [ "palworld.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "palworld";
      Group = "palworld";
      WorkingDirectory = stateDir;
      ExecStart = steamcmdInstall;
      ExecStartPost = "+${pkgs.systemd}/bin/systemctl restart palworld.service";
      TimeoutStartSec = "30min";
    };
  };

  networking.firewall.allowedUDPPorts = [ 8211 ];
}
