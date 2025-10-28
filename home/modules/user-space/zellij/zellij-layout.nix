{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContent = ''
	layout {
		pane borderless=true {
			split_direction "Horizontal"
		}
	}
  '';
in

{
  programs.zellij.enable = true;

  # Write config.kdl directly to ~/.config/zellij/config.kdl
  home.file.".config/zellij/layouts/default.kdl".text = zellijLayoutsContent;
}
