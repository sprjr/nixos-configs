{ config, lib, pkgs, home-manager, ... }:

{
  imports =
    [
      home-manager.nixosModules.home-manager
      /home/patrick/opt/hetzner-box-cifs.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

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
  services.xserver.enable = true;

  # Enable the KDE Plasma desktop environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
 #sound.enable = true;
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

  # Enable Flatpacks
  services.flatpak.enable = true;

  # Nerdfonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" "DroidSansMono" "JetBrainsMono" ]; })
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.patrick = {
    isNormalUser = true;
    description = "patrick";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox
      kate
    ];
  };

# environment.interactiveShellInit = ''
#   alias ls='lsd'
#   alias cat='bat'
#   alias gomuks='docker run -e TERM=xterm -it --rm heywoodlh/gomuks'
#   alias compose2nix-start='nix shell github:aksiksi/compose2nix'
#   alias uptime='uptime;uptime --pretty'
#   alias yt-dl='nix shell -p yt-dlp'
#   alias weather='curl -s v2.wttr.in/'
#   alias bf='du -aBm / 2>/dev/null | sort -nr | head -n 20'
# '';

  programs.mtr.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Packages for every desktop system
  environment.systemPackages = with pkgs; [
    bat
    docker
    docker-compose
    discord
    fzf
    git
    lima
    lsd
    htop
    thermald
    wireguard-tools
    playerctl
    bitwarden
    signal-desktop
    thunderbird
    wget
    vim
    vimPlugins.nvchad
    ollama
    pciutils
    file
    alacritty
    fanctl
    tldr
    teamviewer
    xboxdrv
    gimp
    vlc
    pkgs.gnome-terminal

    ### Net tools ###
    tailscale
    inetutils
    mtr
    lshw
    nmap
    syncthing

    # GNOME Themes
    pkgs.adwaita-icon-theme

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
