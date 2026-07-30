{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContentRemote = ''
	layout {
		pane borderless=true {
			split_direction "Horizontal"
		}
	}
  '';
in

{
  programs.zellij.enable = true;

  home.file.".config/zellij/layouts/remote.kdl".text = zellijLayoutsContentRemote;
}
