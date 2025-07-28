{ config, pkgs, home-manager, ... }:

{
  # Configuration files
  imports = [
    ./modules/general/packages.nix
    ./modules/tools/alacritty.nix
    ./modules/tools/neovim.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/shell.nix
#   ./modules/user-space/hyprland/hyprland.nix
#   ./modules/user-space/hyprland/hyprlock.nix
#   ./modules/user-space/hyprland/hypridle.nix
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

  home.username = "patrick";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/patrick" else "/home/patrick";

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "24.05";
}
