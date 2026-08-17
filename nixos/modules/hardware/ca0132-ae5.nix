# Creative Sound BlasterX AE-5 Plus (CA0132) workarounds
{ pkgs, ... }:

let
  pciAddr = "0000:21:00.0";

  # Finds the hwdep device node for the CA0132 by walking sysfs for its PCI address.
  findHwdep = ''
    find_ca0132_hwdep() {
      for sysdev in /sys/class/sound/hwC*D*; do
        [ -e "$sysdev" ] || continue
        if readlink -f "$sysdev/device" | grep -q '${pciAddr}'; then
          basename "$sysdev"
          return 0
        fi
      done
      return 1
    }
  '';
in
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

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="sound", DEVPATH=="*/${pciAddr}/*", KERNEL=="hwC*D*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ca0132-init.service"
  '';

  systemd.services.ca0132-init = {
    description = "Initialize Creative CA0132 AE-5 output pins and unmute DAC";
    after = [ "sound.target" ];
    wants = [ "ca0132-mixer-guard.service" ];
    before = [ "ca0132-mixer-guard.service" ];
    path = with pkgs; [ alsa-tools coreutils findutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ca0132-init" ''
        set -euo pipefail

        ${findHwdep}

        hwname=$(find_ca0132_hwdep)
        if [ -z "$hwname" ]; then
          echo "CA0132 hwdep device not found for PCI ${pciAddr}" >&2
          exit 1
        fi

        dev="/dev/snd/$hwname"
        echo "CA0132 hwdep device: $dev"

        hda-verb "$dev" 0x0b SET_PIN_WIDGET_CONTROL 0x40
        hda-verb "$dev" 0x0b SET_EAPD_BTLENABLE 0x02
        hda-verb "$dev" 0x0f SET_PIN_WIDGET_CONTROL 0xc0
        hda-verb "$dev" 0x10 SET_PIN_WIDGET_CONTROL 0xc0

        # Two-step DAC unmute: 0 dB kick then -30 dB operating level
        hda-verb "$dev" 0x02 SET_AMP_GAIN_MUTE 0xb05a
        hda-verb "$dev" 0x02 SET_AMP_GAIN_MUTE 0xb03c
      '';
    };
  };

  systemd.services.ca0132-mixer-guard = {
    description = "Re-apply CA0132 DAC unmute on ALSA mixer changes";
    after = [ "ca0132-init.service" ];
    requisite = [ "ca0132-init.service" ];
    bindsTo = [ "ca0132-init.service" ];
    path = with pkgs; [ alsa-utils alsa-tools coreutils findutils ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = pkgs.writeShellScript "ca0132-mixer-guard" ''
        set -euo pipefail

        ${findHwdep}

        hwname=$(find_ca0132_hwdep)
        if [ -z "$hwname" ]; then
          echo "CA0132 hwdep device not found for PCI ${pciAddr}" >&2
          exit 1
        fi

        dev="/dev/snd/$hwname"
        card=''${hwname#hwC}
        card=''${card%%D*}

        echo "Monitoring ALSA card $card ($dev) for mixer changes"

        # Repeated unmute during PipeWire startup window
        for i in 1 2 3 4 5; do
          hda-verb "$dev" 0x02 SET_AMP_GAIN_MUTE 0xb05a 2>/dev/null || true
          hda-verb "$dev" 0x02 SET_AMP_GAIN_MUTE 0xb03c 2>/dev/null || true
          sleep 1
        done

        # Monitor for ongoing mixer changes; debounce 2s before unmuting
        stdbuf -oL alsactl monitor "hw:$card" | while read -r line; do
          while read -t 2 -r _; do :; done
          hda-verb "$dev" 0x02 SET_AMP_GAIN_MUTE 0xb05a 2>/dev/null || true
          hda-verb "$dev" 0x02 SET_AMP_GAIN_MUTE 0xb03c 2>/dev/null || true
        done
      '';
    };
  };
}
