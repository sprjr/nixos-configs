{ config, pkgs, home-manager, ... }:

{
  # Modules
  imports = [
    ./linux/desktop_environments/gnome.nix
    ./modules/general/packages.nix
    ./modules/tools/alacritty.nix
    ./modules/tools/neovim.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/hyprland/hyprland.nix
    ./modules/user-space/hyprland/hyprlock.nix
    ./modules/user-space/hyprland/hypridle.nix
    ./modules/user-space/shell.nix
    ./modules/user-space/waybar/waybar.nix
    ./modules/user-space/zellij/zellij-layout-darwin.nix
    ./modules/user-space/zellij/zellij-config.nix
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "sprjr";
    userEmail = "patrick@rawlinson.ws";
  };

  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/patrick" else "/home/patrick";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home.stateVersion = "24.05";
}
