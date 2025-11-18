{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContent = ''
    layout {
      tab name="main" {
        pane {
          borderless=true
          split_direction="horizontal"
	}
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
