{
  config,
  pkgs,
  home-manager,
  heywoodlh-configs,
  ...
}:

let
  heywoodlh-darwin-modules = (heywoodlh-configs + "/darwin/modules/default.nix");
in
{
  imports = [
    home-manager.darwinModules.home-manager
    heywoodlh-darwin-modules
    ../modules/sketchybar.nix
  ];

  system = {
    primaryUser = "patrick";
    defaults = {
      dock = {
        persistent-apps = [
          "/System/Applications/Messages.app"
          "/Applications/Firefox.app"
          "/System/Applications/System Settings.app"
          "/Applications/Line.app"
          "/Applications/Steam.app"
          "/Applications/Battle.net.app"
          "/Applications/Discord.app"
          "/Applications/Thunderbird.app"
          "/Applications/Ghostty.app"
          "/Applications/1Password.app"
          "/Applications/Signal.app"
        ];
      };
    };
  };

  # Define user settings
  users.users.patrick = {
    description = "Patrick Rawlinson";
    name = "patrick";
    home = "/Users/patrick";
    shell = pkgs.zsh;
    # These packages will only be installed for your user
    # The binaries will be available in the following path: /etc/profiles/per-user/$USER/bin
    packages = [
      pkgs.bash
      pkgs.gcc
      pkgs.git
      pkgs.gnupg
      pkgs.sops
    ];
  };

  # Homebrew configuration
  homebrew = {
    enable = true;
    # Enable auto-clean
    onActivation.cleanup = "zap";
    # Packages / Formulae
    brews = [
      "bash"
      "bat"
      "btop"
      "dcmtk"
      "docker-compose"
      "duf"
      #"firefox" # re-add later
      "fish"
      "glow" # markdown reader
      "htop"
      "kind"
      "lsd"
      "lsusb"
      "mtr"
      "nmap"
      "opentofu"
      "podman"
      "tldr"
      "wireguard-go"
      "wireguard-tools"
      "zsh"
    ];
    extraConfig = ''
      cask_args appdir: "~/Applications"
    '';
    # Casks
    casks = [
      "1password"
      "battle-net"
      "bitwarden"
      "discord"
      "displaylink"
      "docker-desktop"
      "firefox"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "google-chrome"
      "libreoffice"
      "localsend"
      "microsoft-office"
      "microsoft-remote-desktop"
      "minecraft"
      "moonlight"
      "obsidian"
      "signal"
      "steam"
      "tailscale-app"
      "thunderbird"
      "vlc"
    ];
    taps = [
      #"homebrew/cask-drivers"
    ];
  };

  # Home-Manager configuration
  home-manager.users.patrick.imports = [ ../../home/darwin-home.nix ];

  # Preferences
  system = {
    defaults = {
      NSGlobalDomain = {
        _HIHideMenuBar = true;
      };
      controlcenter = {
        BatteryShowPercentage = true;
        Bluetooth = true;
        NowPlaying = true;
      };
      dock.autohide = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Sketchybar and Yabai
  #heywoodlh.darwin.sketchybar.enable = true;
  patrick.darwin.sketchybar.enable = true;
  heywoodlh.darwin.yabai.enable = true;

  system.stateVersion = 4;
}
