{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContent = ''
    layout {
      tab name="main" {
        pane borderless=true {
          split_direction "Horizontal"
        }
        pane command="btop"{
        }
      }
      tab name="second" {
        pane borderless=true {
          split_direction "Horizontal"
        }
        pane {
        }
      }
      tab name="third" {
        pane borderless=true {
          split_direction "Horizontal"
        }
        pane {
        }
      }
      tab name="fourth" {
        pane borderless=true {
          split_direction "Horizontal"
        }
        pane {
        }
      }
    }
  '';
in

{
  programs.zellij.enable = true;

  # Write config.kdl directly to ~/.config/zellij/config.kdl
  home.file.".config/zellij/layouts/default.kdl".text = zellijLayoutsContent;
}
