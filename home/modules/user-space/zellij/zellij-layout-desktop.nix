{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContent = ''
    layout {
      tab name="main" {
        split_direction "Vertical" {
          pane
          pane commmand="btop"
        }
      }

      tab name="second" {
        split_direction "Vertical" {
          pane
          pane
        }
      }
    }
  '';
in
{
  programs.zellij.enable = true;

  home.file.".config/zellij/layouts/default.kdl".text = zellijLayoutsContent;
}
