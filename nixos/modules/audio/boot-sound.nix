{ config, pkgs, lib, ... }:

let
  cfg = config.services.boot-sound;
in {
  options.services.boot-sound = {
    enable = lib.mkEnableOption "boot startup sound";

    soundFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a PCM WAV file to play at boot.";
    };

    device = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "ALSA device string (e.g. plughw:CARD=NVidia,DEV=7). Use plughw: for automatic format conversion.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.boot-sound = {
      description = "Play startup sound";
      wants = [ "sound.target" ];
      after = [ "sound.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        ExecStart = "${pkgs.writeShellScript "boot-sound-play" ''
          ${pkgs.alsa-utils}/bin/aplay -D ${cfg.device} ${cfg.soundFile}
        ''}";
      };
    };
  };
}
