{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContent = ''
    layout {
      tab name="main" split_direction="horizontal" {
        pane { borderless=true }
        pane command="btop"
      }

      tab name="second" split_direction="horizontal" {
        pane { borderless=true }
        pane
      }
    }
  '';
in
{
  programs.zellij.enable = true;

  home.file.".config/zellij/layouts/default.kdl".text = zellijLayoutsContent;
}
