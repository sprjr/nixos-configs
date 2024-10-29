{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContent = ''
	layout {
		pane {
			split_direction "Horizontal"
		}
		pane {
			split_direction "Vertical"
			pane {
			}
			pane {
				command "htop"
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
