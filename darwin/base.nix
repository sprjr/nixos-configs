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
    name = "patrick";
    home = "/Users/patrick";
    shell = pkgs.zsh;
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

  # Homebrew configuration
  homebrew = {
    enable = true;
    # Packages
    brews = [
      "bash"
      "bat"
      "duf"
      "htop"
      "hyfetch"
      "lsd"
      "tldr"
      "watch"
      "zsh"
    ];
    extraConfig = ''
      cask_args appdir: "~/Applications"
    '';
    # Casks
    casks = [
      "bitwarden"
      "docker"
      "font-jetbrains-mono-nerd-font"
      "iterm2"
      "obsidian"
      "signal"
      "syncthing"
      "tailscale"
      "vmware-fusion"
    ];
  };

  # Set the nix daemon
  services.nix-daemon.enable = true;

  # Home-Manager configuration
  home-manager.users.patrick.imports = [ ../home/home.nix ];

  # Hide the top bar
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  # Sketchybar and Yabai
  heywoodlh.darwin.sketchybar.enable = true;
  heywoodlh.darwin.yabai.enable = true;

  system.stateVersion = 4;
}

