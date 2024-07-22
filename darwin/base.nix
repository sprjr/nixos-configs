{ config, pkgs, home-manager, ... }:


{
  imports = [
    home-manager.darwinModules.home-manager
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

  # Home-Manager configuration
  home-manager.users.patrick.imports = [ ../home/home.nix ];

  system.stateVersion = 4;
}

