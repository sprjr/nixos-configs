{
  config,
  pkgs,
  lib,
  home-manager,
  dark-wallpaper-laptop,
  nixpkgs-stable,
  ...
}:

let
  system = pkgs.system;
  pkgs-stable = nixpkgs-stable.legacyPackages.${system};
in
{
  imports = [
    ./modules/system/sops.nix
    ./modules/system/btrfs-config.nix
    ./modules/system/esp-tooling.nix
  ];

  users.mutableUsers = false;
  users.users.patrick = {
    hashedPasswordFile = "/var/lib/secrets/default-user.hash";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYxyYpBB8K35/1+c22hBDV6mQFkqvxJeBC/SWs8Yyh+"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYxyYpBB8K35/1+c22hBDV6mQFkqvxJeBC/SWs8Yyh+"
  ];

  # Zen Kernel (default is undeclared, or `pkgs.linuxPackages_latest;`
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  console.keyMap = "us";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # General Networking Options
  networking.hostName = "voyager"; # Define your hostname.

  # Disable NetworkManager-wait-online.service
  systemd.services.NetworkManager-wait-online.enable = false;

  # Disable Orca screen reader (CosmicDE)
  services.orca.enable = false;

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable resolved to handle DNS issue after sleeping
  networking.nameservers = [
    " 1.1.1.1#one.one.one.one"
    "1.0.0.1#one.one.one.one"
  ];
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
    ];
    dnsovertls = "true";
  };

  # Firewall Port allowances
  networking.firewall.allowedTCPPortRanges = [
    # KDE Connect
    {
      from = 1714;
      to = 1764;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    # KDE Connect
    {
      from = 1714;
      to = 1764;
    }
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

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Fonts
  fonts.packages = [
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.jetbrains-mono
  ];

  home-manager = {
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        ../home/laptop-home.nix
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Gaming
  programs.steam.enable = true;
  services.flatpak.enable = true;

  # VPN/Mesh Network
  services.tailscale.enable = true;
  # to fix broken internet when using an exit node
  networking.firewall.checkReversePath = "loose";
  networking.wireguard.enable = true;

  # 1Password
  programs._1password = {
    enable = true;
  };
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "patrick" ];
  };

  # Needed this to run bash scripts
  services.envfs.enable = true;

  # System packages
  environment.systemPackages =
    with pkgs;
    [
      # Misc and System
      attic-client
      gcompris # educational stuff for kids
      git
      pciutils
      pipewire
      python314 # need this for cht() function at least
      python314Packages.pip
      thermald
      wget

      # User environment
      duplicati

      file
      fzf
      ffmpeg
      gh-dash
      ghostty
      home-manager
      kitty
      legcord
      mdp # fullscreen markdown reader
      moonlight-qt
      mumble
      mdp # fullscreen markdown reader
      moonlight-qt
      mumble
      obsidian
      prismlauncher
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

      ### Net tools ###
      pkgs-stable.tailscale
      bandwhich
      inetutils
      iproute2
      lshw
      netop
      nmap
      wireguard-tools
      wireguard-ui
      wireshark

      # Work Tools
      opentofu
      remmina
      terraformer

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
      wireguard-tools
      wireguard-ui
      wireshark

      # Work Tools
      opentofu
      remmina
      terraformer

      # scrcpy packages
      android-tools
      libusb1
      meson
      pkg-config

      # Temporary: remove later
      google-chrome # esp32 stuff
    ]
    ++ [
      # Pinned to stable
    ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
    };
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "delete-older-than 14d";
  };

  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;

  system.stateVersion = "24.11"; # Did you read the comment?
}
