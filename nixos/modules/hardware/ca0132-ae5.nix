# Creative Sound BlasterX AE-5 Plus (CA0132) workarounds.
# The ca0132 kernel driver loads DSP firmware but fails to enable output
# pin widgets on the AE-5. PipeWire hardware volume writes also re-mute
# the DAC by setting the amp mute bit. A PipeWire loopback provides
# software volume control without touching the hardware mixer.
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
    ]
  '';

  services.pipewire.extraConfig.pipewire."91-ca0132-loopback" = {
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "Sound BlasterX AE-5";
          "capture.props" = {
            "node.name" = "ae5-headphones";
            "media.class" = "Audio/Sink";
            "audio.position" = [ "FL" "FR" ];
          };
          "playback.props" = {
            "node.name" = "ae5-headphones-playback";
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
}
