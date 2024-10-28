{ config, pkgs, home-manager, lib, ... }:

let
  zellijConfig = pkgs.writeTextFile {
    name = "config.kdl";
    text = ''
      layout {
        default layout {
          pane {
            split_direction "Horizontal"
          }
          pane {
            split_direction "Vertical"
            pane {
            }
            pane {
              command "btop"
            }
          }
        }
      }
      theme "nord"
      themes {
        nord {
          bg "#2E3440"
          black "#3B4252"
          blue "#81A1C1"
          cyan "#88C0D0"
          fg "#D8DEE9"
          green "#A3BE8C"
          magenta "#B48EAD"
          orange "#D08770"
          red "#BF616A"
          white "#E5E9F0"
          yellow "#EBCB8B"
        }
      }
    '';
  };
in

{
  programs.zellij = {
    enable = true;
    settings.config = zellijConfig;
  };
}

