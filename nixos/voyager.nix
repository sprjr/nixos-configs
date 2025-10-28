{ config, pkgs, lib, home-manager, nixpkgs-stable, ... }:

let
  system = pkgs.system;
  pkgs-stable = nixpkgs-stable.legacyPackages.${system};
in {
  imports = [
    ./modules/system/sops.nix
  ];

  # ESP32 Serial Converter
  boot.kernelModules = [
    "cp210x"
    "cp341"
  ];
  services.udev.extraRules = ''
    # Allow dialout group access to USB serial devices
    KERNEL=="ttyUSB[0-9]*", MODE="0660", GROUP="dialout"
  '';
  users.users.patrick.extraGroups = [ "dialout" ];

  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Zen Kernel (default is undeclared, or `pkgs.linuxPackages_latest;`
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # General Networking Options
  networking.hostName = "voyager"; # Define your hostname.
# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant !! cannot use with networking.networkmanager.enable = true

  # Disable NetworkManager-wait-online.service
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true; # GUI management

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable resolved to handle DNS issue after sleeping
  networking.nameservers = [" 1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    dnsovertls = "true";
  };

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

  # Enable the KDE Plasma Desktop Environment.
# services.displayManager.sddm.enable = true;
# services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
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
  };

  # Nethogs rules (probably want to re-do this)
  security.sudo.extraRules = [
    {
      users = [ "patrick" ];
      commands = [
        { command = "${pkgs.nethogs}/bin/nethogs"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

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
  nixpkgs.config.segger-jlink.acceptLicense = true; # For nRF Utility tools

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

  # Home-Manager configuration
# home-manager = {
#   backupFileExtension = "backup";
   #users.patrick.imports = [ ../home/hyprland-home.nix ];
# };

  # Needed this to run bash scripts
  services.envfs.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    attic-client
    git
    pciutils
    pipewire
    thermald
    wget

    # User environment
    btop
    pkgs-stable.bitwarden
    pkgs-stable.bitwarden-cli
    discord
    duplicati
    file
    floorp-bin # Privacy-focused Firefox fork
    fzf
    ghostty
    home-manager
    kitty
    libreoffice
    mdp # fullscreen markdown reader
    moonlight-qt
    mullvad-browser
    nautilus
    nrfconnect
    nrfutil
    obsidian
    scrcpy
    signal-desktop
    sops
    thunderbird
    ulauncher
    usbutils
    vim
    vimPlugins.nvchad
    vlc
    zsh

    # ESP32 stuff
    esptool
    python313
    python313Packages.cryptography
    python313Packages.pip

    # Hyprland
#   hyprsession.packages.${pkgs.system}.default
#   hyprland
#   hyprlock
#   hyprpaper
#   hyprlandPlugins.hyprspace
#   ulauncher
    xdg-utils

    ### Net tools ###
    pkgs-stable.tailscale
    bandwhich
    inetutils
    iproute2
    mullvad-vpn
    nethogs
    nextcloud-client
    lshw
    netop
    nmap
   #openvas-scanner
    sysstat
    wireguard-tools
    wireguard-ui
    wireshark
    xpipe

    # Work Tools
    opentofu
    remmina
    weasis

    # scrcpy packages
    android-tools
    libusb1
    meson
    pkg-config
  ] ++ [
    # Pinned to stable
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
