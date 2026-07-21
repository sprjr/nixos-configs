{ config, lib, pkgs, home-manager, ... }:

{
  imports =
    [
      home-manager.nixosModules.home-manager
#     /home/patrick/opt/hetzner-box-cifs.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.channel.enable = false;

  # Firewall Port allowances
  networking.firewall.allowedTCPPortRanges = [
    # KDE Connect
    { from = 1714; to = 1764; }
  ];
  networking.firewall.allowedUDPPortRanges = [
    # KDE Connect
    { from = 1714; to = 1764; }
  ];

  # Rooted Docker Configuration ### Added user to extra groups below
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker = {
#   enableNvidia = true;
    enable = true;
  };

  # Podman Configuration
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
#      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
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

  # Tailscaled
  services.tailscale.enable = true;

  # Enable the X11 windowing system.
 #services.xserver.enable = true;

  # Enable the KDE Plasma desktop environment.
 #services.displayManager.sddm.enable = true;
 #services.desktopManager.plasma6.enable = true;


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
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Nerdfonts
  fonts.packages = [
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.patrick = {
    isNormalUser = true;
    description = "patrick";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      kate
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages (user-specific packages live in home-manager profiles)
  environment.systemPackages = with pkgs; [
    fanctl
    file
    git
    lshw
    ollama
    pciutils
    tailscale
    thermald
    vim
    wget
  ];

  # Host-specific packages for patrick (not needed system-wide)
  users.users.patrick.packages = with pkgs; [
    adwaita-icon-theme
    bitwarden
    discord
    gimp
    gnome-terminal
    open-webui
    playerctl
    teamviewer
    tinystatus
  ];

  system.stateVersion = "23.11";

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
