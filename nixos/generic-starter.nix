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
  networking.hostName = "starter"; # Define your hostname.
# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant !! cannot use with networking.networkmanager.enable = true

  # Disable NetworkManager-wait-online.service
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Tailscale
  services.tailscale.enable = true;

  # Mullvad
  services.mullvad-vpn.enable = true;
  networking.iproute2.enable = true;

  # Wireguard
  networking.wireguard.enable = true;

  # 1Password
  programs._1password = { enable = true; };
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "patrick" ];
  };

  # Needed this to run bash scripts
  services.envfs.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    git
    wget

    # User environment
    btop
    file
    fzf
    mdp # fullscreen markdown reader
    sops
    vim
    vimPlugins.nvchad
    zsh

    ### Net tools ###
    inetutils
    mullvad-vpn
    lshw
    netop
    nmap
    openvas-scanner
    wireguard-tools
    wireguard-ui
    wireshark
    xpipe

    # Operations tools
    opentofu

  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "delete-older-than 14d";
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
