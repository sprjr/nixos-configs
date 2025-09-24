{ config, pkgs, lib, home-manager, nixpkgs-stable, ... }:

let
  system = pkgs.system;
  pkgs-stable = nixpkgs-stable.legacyPackages.${system};
in {
  imports = [
    home-manager.nixosModules.home-manager
#   ./modules/desktop-environment/gnome.nix
#   ../home/linux/desktop_environments/gnome-dconf.nix
    ./modules/gaming/windows-vm.nix
  ];

  # Select Desktop Environment.
  # Plasma
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Zen Kernel (default is undeclared, or `pkgs.linuxPackages_latest;`
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-f9b0a070-8711-4b4a-84ac-a70044729daf".device = "/dev/disk/by-uuid/f9b0a070-8711-4b4a-84ac-a70044729daf";
  networking.hostName = "seanix"; # Define your hostname.

  # Disable NetworkManager-wait-online.service
  systemd.services.NetworkManager-wait-online.enable = false;

  # TEMPORARY Allow Broken
  nixpkgs.config.allowBroken = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Windows VM Boot Toggler
  specialisation."VFIO".configuration = {
    system.nixos.tags = [ "with-vfio" ];
    vfio.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true; # GUI management

  # Enable networking
  networking.networkmanager.enable = true; # Cannot be used with "networking.wireless.enable = true"
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Firewall Port allowances
  networking.firewall.allowedTCPPortRanges = [
    # KDE Connect
    { from = 1714; to = 1764; }
  ];
  networking.firewall.allowedUDPPortRanges = [
    # KDE Connect
    { from = 1714; to = 1764; }
  ];

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
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  home-manager = {
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        ../home/linux-home.nix
      ];
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Fonts
  fonts.packages = [
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable OpenRGB udev rules
  services.hardware.openrgb.enable = true;

  # Enable Steam
  programs.steam.enable = true;

  # Flatpaks
  services.flatpak.enable = true;

  # Tailscale
  services.tailscale.enable = true;
  # to fix broken internet when using an exit node
  networking.firewall.checkReversePath = "loose";


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
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    fanctl
    git
    pciutils
    pipewire
   #python313Full
    python313Packages.pip
    thermald
    wget

    # AWS stuff
    awscli2
    aws-sam-cli
    python311
    python311Packages.boto3
    python311Packages.pip

    # AV utilities
    alsa-plugins
    alsa-utils
    obs-studio
    pavucontrol
    pulseaudio
    qjackctl

    # User environment
    alacritty
    btop-rocm
    pkgs-stable.bitwarden
    pkgs-stable.bitwarden-cli
    legcord # alt discord client
    direnv
    discord
    distrobox
    distrobox-tui
    duplicati
    esptool
    file
    floorp-bin # Privacy-focused Firefox alternative
    freetube
    fzf
    gamescope
    gimp
    libreoffice
    lyrebird
    mdp # fullscreen markdown reader
    moonlight-qt
    mullvad-browser
    mumble
    obsidian
    ollama-rocm
    python313Packages.openrazer
    rpi-imager
    scrcpy
    signal-desktop
    sops
    thunderbird
    vim
    vimPlugins.nvchad
    vlc
    xbindkeys-config # graphic interface for xbindkeys (input mapper)
    zsh

    ### Net tools ###
    tailscale
    inetutils
    mullvad-vpn
    nextcloud-client
    looking-glass-client
    lshw
    nethogs # shows bandwidth usage by application
    netop
    nmap
    openvas-scanner
    usbutils
    wireguard-tools
    wireguard-ui
    wireshark
    xpipe

    # PyTorch
    python313Packages.matplotlib
    python313Packages.nibabel # dicom-specific
    python313Packages.numpy
    python313Packages.opencv-python
    python313Packages.pandas
    python313Packages.pydicom # dicom-specific
    python313Packages.scikit-learn
    python313Packages.torch
    python313Packages.torchaudio
    python313Packages.torchvision

    # Work Tools
    opentofu
    remmina
    weasis

    # KDE Packages
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.kdeconnect-kde
    kdePackages.kiten
    kdePackages.konsole
    kdePackages.krdp

    # scrcpy packages
    android-tools
    libusb1
    meson
    pkg-config

    # Gaming
    heroic
    prismlauncher
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Garbage collect
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "delete-older-than 14d";
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
