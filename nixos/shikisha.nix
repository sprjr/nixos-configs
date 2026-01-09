{ config, pkgs, lib, home-manager, nixpkgs-stable, ... }:

let
  system = pkgs.system;
  pkgs-stable = nixpkgs-stable.legacyPackages.${system};
in {
  imports = [
    home-manager.nixosModules.home-manager
    # Systemd Timers
    ./hosts/shikisha/cron/docker-findmy-restart.nix
  ];

  # Zen Kernel (default is undeclared, or `pkgs.linuxPackages_latest;`
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ESP32 serial converter
  boot.kernelModules = [
    "cp210x"
   #"cp341" # Not needed at this time; current model is a cp2102
  ];

  # General Networking Options
  networking.hostName = "shikisha"; # Define your hostname.
# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant !! cannot use with networking.networkmanager.enable = true

  networking.firewall = {
    allowedUDPPorts = [ 8472 ];
  };

  # Disable NetworkManager-wait-online.service
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Allow broken; pin textual (since it's broken)
  nixpkgs.config.allowBroken = true;

  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages.overrideScope (pyFinal: pyPrev: {
        textual = pyPrev.textual.overridePythonAttrs (old: {
      doCheck = false; # skip failed tests
    });
      });
    })
  ];

  ### REMOVE THIS WHEN YOU CAN ###
  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
    "qtwebengine-5.15.19"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    attic-server
    attic-client
    cachix
    git
    usbutils
    pciutils
    pipewire
    thermald
    wget

    # User environment
    btop
    duplicati
    esptool
    file
    fzf
    gnumake # makefile ^ alternative
    kiwix
    kiwix-tools
    mdp # fullscreen markdown reader
    sops
    vim
    vimPlugins.nvchad
    zsh

    # ESP32 stuff
    esptool
   #python313
   #python313Packages.cryptography
   #python313Packages.pip

    ### Net tools ###
    inetutils
    mullvad-vpn
    lshw
    netop
    nmap
    xpipe

    # Docker OSX/macOS
   #bridge-utils
   #libvirt
   #virt-manager
   #qemu
   #qemu_kvm

    # Operations tools
    argocd
    garage
    kubeseal
    openiscsi
    opentofu
  ] ++ [
    # Pinned to Stable
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "delete-older-than 14d";
  };

  # nix-store optimization
  nix.optimise.automatic = true;
  system.stateVersion = "24.11"; # Did you read the comment?
}
