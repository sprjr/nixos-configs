{ config, pkgs, home-manager, ... }:

{
  home.file = {
    ".local/bin/switch-local.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        kscreen-doctor \
          output.DP-1.enable output.DP-1.mode.2 output.DP-1.position.3191,1080 output.DP-1.scale.1 \
          output.DP-2.enable output.DP-2.mode.16 output.DP-2.position.1920,1080 output.DP-2.scale.1.7 output.DP-2.rotation.left \
          output.DP-3.enable output.DP-3.mode.45 output.DP-3.position.5751,1080 output.DP-3.scale.1.6 \
          output.HDMI-A-1.disable
      '';
    };

    ".local/bin/switch-remote.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        kscreen-doctor \
          output.HDMI-A-1.enable output.HDMI-A-1.mode.74 output.HDMI-A-1.position.0,0 output.HDMI-A-1.scale.1 \
          output.DP-1.disable \
          output.DP-2.disable \
          output.DP-3.disable
      '';
    };
  };
}
