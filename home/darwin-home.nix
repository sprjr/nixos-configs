{ config, pkgs, home-manager, ... }:

{
  # Modules
  imports = [
    ./modules/user-space/bat.nix
    ./modules/user-space/shell.nix
    ./modules/user-space/zellij/zellij-layout-darwin.nix
    ./modules/user-space/zellij/zellij-config.nix
    ./modules/tools/ghostty.nix
    ./modules/tools/neovim.nix
    ./modules/general/packages.nix
  ];

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "sprjr";
        email = "patrick@rawlinson.ws";
      };
    };
  };

  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/patrick" else "/home/patrick";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home.stateVersion = "24.05";
}
