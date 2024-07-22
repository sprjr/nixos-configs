{ config, pkgs, home-manager, heywoodlh-configs, ... }:

let
  heywoodlh-darwin-modules = (heywoodlh-configs + "/darwin/modules/default.nix");
in {
  imports = [
    home-manager.darwinModules.home-manager
    heywoodlh-darwin-modules
  ];

  # Define user settings
  users.users.patrick = {
    description = "Patrick Rawlinson";
    name = "Patrick Rawlinson";
    shell = pkgs.bash;
    # These packages will only be installed for your user
    # The binaries will be available in the following path: /etc/profiles/per-user/$USER/bin
    packages = [
      pkgs.bash
      pkgs.gcc
      pkgs.git
      pkgs.gnupg
      pkgs.tmux
    ];
  };

  # Set the nix daemon
  services.nix-daemon.enable = true;

  # Home-Manager configuration
  home-manager.users.patrick.imports = [ ../home/home.nix ];

  # Hide the top bar
  system.defaults.NSGlobalDomain._HIHideMenuBar

  # Sketchybar and Yabai
  heywoodlh.darwin.sketchybar.enable = true;
  heywoodlh.darwin.yabai.enable = true;

  system.stateVersion = 4;
}

