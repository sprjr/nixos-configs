{ config, pkgs, lib, home-manager, nixpkgs-stable, ... }:

let
  system = pkgs.system;
  pkgs-stable = nixpkgs-stable.legacyPackages.${system};
in {
  imports = [
    home-manager.nixosModules.home-manager
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # General Networking Options
  networking.hostName = "shikisha"; # Define your hostname.
  # Enable networking
  networking.networkmanager.enable = true;

  # Disable NetworkManager-wait-online.service
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable Docker and Podman
  virtualisation = {
      docker.enable = true;
      podman.enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the KDE Plasma Desktop Environment.
# services.displayManager.sddm.enable = true;
# services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Fonts
  fonts.packages = [
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # Needed this to run bash scripts
  services.envfs.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    git
    pciutils
    wget

    # User environment
    btop
    duplicati
    file
    fzf
    k0sctl
    sops
    tree
    vim
    vimPlugins.nvchad
    zsh

    ### Net tools ###
    pkgs-stable.tailscale
    inetutils
    lshw
    nmap
    openvas-scanner
    wireshark
    xpipe

    # Work Tools
    opentofu
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?
}
