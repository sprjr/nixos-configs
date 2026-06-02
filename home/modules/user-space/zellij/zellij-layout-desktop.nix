{ config, pkgs, home-manager, ... }:

let
  zellijLayoutsContentDesktop = ''
    layout {
      tab name="monitor" {
        pane split_direction="Vertical" {
          pane command="nvtop" {}
          pane command="htop" {}
        }
      }
      tab name="work" {
        pane split_direction="Vertical" {
          pane cwd="${config.home.homeDirectory}/.nixos/nixos-configs" {}
          pane cwd="${config.home.homeDirectory}/.nixos/nixos-configs" {}
        }
      }
      tab name="misc" {
        pane split_direction="Vertical" {
          pane {}
          pane {}
        }
      }
    }
  '';

in
{
  programs.zellij.enable = true;

  home.file.".config/zellij/layouts/default.kdl" = {
    text = zellijLayoutsContentDesktop;
  };
}
