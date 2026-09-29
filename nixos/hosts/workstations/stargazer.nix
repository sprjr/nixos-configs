{
  config,
  pkgs,
  lib,
  nixpkgs-stable,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  pkgs-stable = nixpkgs-stable.legacyPackages.${system};
in
{
  imports = [ ../../modules/system/sops.nix ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.extraModprobeConfig = "options thinkpad_acpi fan_control=1";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "stargazer";

  users.mutableUsers = false;
  users.users.patrick.hashedPasswordFile = "/var/lib/secrets/default-user.hash";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYxyYpBB8K35/1+c22hBDV6mQFkqvxJeBC/SWs8Yyh+"
  ];

  systemd.services.NetworkManager-wait-online.enable = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.channel.enable = false;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.enableRedistributableFirmware = true;

  networking.networkmanager.enable = true;

  # KDE Connect
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 1714;
      to = 1764;
    }
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 1714;
      to = 1764;
    }
  ];

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32768;
    }
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  time.timeZone = "America/Denver";

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

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  services.thermald.enable = true;

  services.thinkfan = {
    enable = true;
    sensors = [
      {
        type = "tpacpi";
        query = "/proc/acpi/ibm/thermal";
      }
    ];
    fans = [
      {
        type = "tpacpi";
        query = "/proc/acpi/ibm/fan";
      }
    ];
    levels = [
      [
        0
        0
        42
      ]
      [
        1
        40
        48
      ]
      [
        2
        45
        53
      ]
      [
        3
        50
        58
      ]
      [
        4
        55
        63
      ]
      [
        5
        58
        68
      ]
      [
        7
        63
        75
      ]
      [
        "level full-speed"
        70
        32767
      ]
    ];
  };

  fonts.packages = [
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.jetbrains-mono
  ];

  home-manager = {
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        ../../../home/laptop-home.nix
      ];

      # 15.6" 3840x2160 panel: 1.2 leaves 3200x1800 logical, too dense to use.
      patrick.home.hyprland.monitors = lib.mkForce [
        "eDP-1,preferred,auto,2.0"
        ",preferred,auto,auto"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  programs.steam.enable = true;
  services.flatpak.enable = true;
  services.flatpak.packages = [
    "io.github.maniacx.BudsLink"
  ];

  services.tailscale.enable = true;
  # to fix broken internet when using an exit node
  networking.firewall.checkReversePath = "loose";
  networking.wireguard.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "patrick" ];
  };

  # Needed this to run bash scripts
  services.envfs.enable = true;

  environment.systemPackages = with pkgs; [
    file
    git
    home-manager
    iproute2
    lshw
    pciutils
    pipewire
    pkgs-stable.tailscale
    sops
    usbutils
    vim
    wget
    zsh
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise.automatic = true;

  system.stateVersion = "25.11";
}
