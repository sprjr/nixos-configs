{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.zellij;
in {
  options = {
    programs.zellij = {
      enable = true;
      layout = lib.mkOption {
        type = lib.types.str;
	description = "Layout for Zellij";
	default = ''
	  layout {
	  	pane {
			split_direction "Horizontal"
			borderless true
		}
		pane {
			split_direction "Vertical"
			pane {
				borderless true
			}
			pane {
				command "btop"
			}
		}
	  }
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    home.packages = [pkgs.zellij];
    home.file.".config/zellij/layouts/default.kdl".text = cfg.layout;
  };
}
