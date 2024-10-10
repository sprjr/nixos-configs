{ config, pkgs, lib, home-manager, nixpkgs-stable, ... }:

let
  system = pkgs.system;
  pkgs-stable = nixpkgs-stable.legacyPackages.${system};
in {
  imports =
    [
      home-manager.nixosModules.home-manager
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-f9b0a070-8711-4b4a-84ac-a70044729daf".device = "/dev/disk/by-uuid/f9b0a070-8711-4b4a-84ac-a70044729daf";
  networking.hostName = "seanix"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Disable NetworkManager-wait-online.service
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true; # GUI management

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable Wake on Lan
  networking.interfaces.enp34s0.wakeOnLan.enable = true;

  # Firewall Port allowances
  networking.firewall.allowedTCPPortRanges = [
    # KDE Connect
    { from = 1714; to = 1764; }
  ];
  networking.firewall.allowedUDPPortRanges = [
    # KDE Connect
    { from = 1714; to = 1764; }
  ];

  # Enable Docker
  virtualisation.docker = {
    enable = true;
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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE Plasma default package exclusions
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
   #konsole
  ];


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.patrick = {
    isNormalUser = true;
    description = "Patrick";
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [
      kdePackages.kate
      (wineWowPackages.full.override {
        wineRelease = "staging";
        mingwSupport = true;
      })
      winetricks
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" "DroidSansMono" "JetBrainsMono" ]; })
  ];


  # Install firefox.
 #programs.firefox.enable = true;

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

  # Mullvad
  services.mullvad-vpn.enable = true;
  networking.iproute2.enable = true;

  # Wireguard
  networking.wireguard.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    fanctl
    geckodriver
    git
    pciutils
    pipewire
    thermald
    wireguard-tools
    wget

    # User environment
    alacritty
    btop
    pkgs-stable.bitwarden
    pkgs-stable.bitwarden-cli
    cli-visualizer
    discord
    duplicati
    file
    freerdp
    fzf
    gamescope
    gimp
    helix
    hyfetch
    kitty
    mdp # fullscreen markdown reader
    mullvad-browser
    obs-studio
    obsidian
    openrgb-with-all-plugins # also check the above rules for services.hardware.openrgb.enable = true;
    scrcpy
    signal-desktop
    thunderbird
    tmux
    tree
    vim
    vimPlugins.nvchad
    weasis

    ### Net tools ###
    tailscale
    inetutils
    mullvad-vpn
    nextcloud-client
    lshw
    nmap
    openvas-scanner
    remmina
    wireguard-tools
    wireshark
    xpipe

    # KDE Packages
    kdePackages.kate
    kdePackages.kdeconnect-kde
    kdePackages.kiten
    kdePackages.krdp

    # scrcpy packages
    android-tools
    libusb1
    meson
    pkg-config

    # Gaming
    prismlauncher
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "24.05"; # Did you read the comment?

  # Home-Manager
  home-manager = {
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        ../home/home.nix
      ];
    };
  };
}
