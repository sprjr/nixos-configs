{ config, pkgs, home-manager, heywoodlh-configs, ... }:

let
  heywoodlh-darwin-modules = (heywoodlh-configs + "/darwin/modules/default.nix");
in {
  imports = [
    home-manager.darwinModules.home-manager
    heywoodlh-darwin-modules
  ];

  system.primaryUser = "patrick";

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
    ];
  };

  # Homebrew configuration
  homebrew = {
    enable = true;
    # Enable auto-clean
    onActivation.cleanup = "zap";
    # Packages / Formulae
    brews = [
      "bash"
      "bat"
      "btop"
      "docker-compose"
      "duf"
     #"firefox" # re-add later
      "fish"
      "glow" # markdown reader
      "golang"
      "htop"
      "hyfetch"
      "lsd"
      "mtr"
      "nmap"
      "ollama"
      "opentofu"
      "sops"
      "tldr"
      "watch"
      "zsh"
    ];
    extraConfig = ''
      cask_args appdir: "~/Applications"
    '';
    # Casks
    casks = [
      "1password"
      "battle-net"
      "bitwarden"
      "discord"
      "docker"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "iterm2"
      "microsoft-remote-desktop"
      "minecraft"
      "moonlight"
      "mullvadvpn"
      "obsidian"
      "orbstack"
      "shortcat"
      "signal"
      "steam"
      "syncthing"
     #"tailscale"
      "thunderbird"
      "vlc"
      "vmware-fusion"
      "wine-stable"
    ];
    taps = [
    ];
  };

  # Set the nix daemon
# services.nix-daemon.enable = true; # remove if unneeded

  # Home-Manager configuration
  home-manager.users.patrick.imports = [ ../home/darwin-home.nix ];

  # Hide the top bar
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  # Sketchybar and Yabai
  heywoodlh.darwin.sketchybar.enable = true;
  heywoodlh.darwin.yabai.enable = true;

  system.stateVersion = 4;
}

