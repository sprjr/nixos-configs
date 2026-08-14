# Creative Sound BlasterX AE-5 Plus (CA0132) workarounds
{ pkgs, ... }:
{
  environment.etc."wireplumber/wireplumber.conf.d/51-ca0132-ae5.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            device.name = "alsa_card.pci-0000_21_00.0"
          }
        ]
        actions = {
          update-props = {
            api.acp.auto-profile = true
          }
        }
      }
      {
        matches = [
          {
            node.name = "~alsa_output.pci-0000_21_00.0.*"
          }
        ]
        actions = {
          update-props = {
            priority.session = 0
          }
        }
      }
    ]
  '';

  services.pipewire.extraConfig.pipewire."91-ca0132-loopback" = {
    "context.objects" = [
      {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "ae5-headphones";
          "node.description" = "Sound BlasterX AE-5";
          "media.class" = "Audio/Sink";
          "object.linger" = true;
          "audio.position" = [ "FL" "FR" ];
          "priority.session" = 1500;
          "monitor.channel-volumes" = true;
        };
      }
    ];
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "capture.props" = {
            "node.name" = "ae5-bridge-capture";
            "node.target" = "ae5-headphones";
            "stream.capture.sink" = true;
            "audio.position" = [ "FL" "FR" ];
            "node.passive" = true;
          };
          "playback.props" = {
            "node.name" = "ae5-bridge-playback";
            "node.target" = "alsa_output.pci-0000_21_00.0.analog-stereo";
            "audio.position" = [ "FL" "FR" ];
            "node.passive" = true;
            "stream.dont-remix" = true;
          };
        };
      }
    ];
  };

  systemd.services.ca0132-init = {
    description = "Initialize Creative CA0132 AE-5 output pins and unmute DAC";
    after = [ "sound.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.alsa-tools ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = pkgs.writeShellScript "ca0132-init" ''
        hda-verb /dev/snd/hwC0D1 0x0b SET_PIN_WIDGET_CONTROL 0x40
        hda-verb /dev/snd/hwC0D1 0x0b SET_EAPD_BTLENABLE 0x02
        hda-verb /dev/snd/hwC0D1 0x0f SET_PIN_WIDGET_CONTROL 0xc0
        hda-verb /dev/snd/hwC0D1 0x10 SET_PIN_WIDGET_CONTROL 0xc0
        hda-verb /dev/snd/hwC0D1 0x02 SET_AMP_GAIN_MUTE 0xb03c
      '';
    };
  };

  systemd.services.ca0132-mixer-guard = {
    description = "Re-apply CA0132 DAC unmute on ALSA mixer changes";
    after = [ "sound.target" "ca0132-init.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ alsa-utils alsa-tools coreutils ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
      ExecStart = pkgs.writeShellScript "ca0132-mixer-guard" ''
        stdbuf -oL alsactl monitor | while read -r line; do
          hda-verb /dev/snd/hwC0D1 0x02 SET_AMP_GAIN_MUTE 0xb03c 2>/dev/null
        done
      '';
    };
  };
}
