{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContent = ''
    layout {
      tab name="main" borderless="true" split_direction="horizontal" {
        pane
        pane command="btop"
      }

      tab name="second" borderless="true" split_direction="horizontal" {
        pane
        pane
      }
    }
  '';
in
{
  programs.zellij.enable = true;

  home.file.".config/zellij/layouts/default.kdl".text = zellijLayoutsContent;
}
