{
  config,
  pkgs,
  home-manager,
  ...
}:

{
  # Modules
  imports = [
    ./linux/desktop_environments/gnome.nix
    ./modules/general/packages.nix
    ./modules/tools/alacritty.nix
    ./modules/tools/claude.nix
    ./modules/tools/opencode.nix
    ./modules/tools/ghostty.nix
    ./modules/tools/neovim.nix
    ./modules/tools/helix/config.nix
    ./modules/tools/helix/languages.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/btop.nix
    ./modules/user-space/colors.nix
    ./modules/user-space/monitor-switch.nix
    ./modules/user-space/hyprland
    ./modules/user-space/shell.nix
    ./modules/user-space/zellij/zellij-layout-desktop.nix
    ./modules/user-space/zellij/zellij-config.nix
  ];

  # Independent, login-selectable Hyprland session (additive to the KDE/GNOME session).
  # seanix: three-monitor layout translated from monitor-switch.nix (fallback line last for
  # hotplug) and the Nvidia session env/GPU widget.
  patrick.home.hyprland = {
    enable = true;
    gpu = "nvidia";
    monitors = [
      "DP-2,3840x2160@60,1920x1080,1.7"
      "DP-1,2560x1440@165,4179x1080,1"
      "DP-3,3840x2160@60,6739x1080,1.6"
      "HDMI-A-1,disable"
      ",preferred,auto,auto"
    ];
  };

  # Git configuration
  programs.git = {
    signing.format = null;
    enable = true;
    settings = {
      user = {
        name = "sprjr";
        email = "patrick@rawlinson.ws";
      };
    };
  };

  home = {
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/patrick" else "/home/patrick";
    username = "patrick";
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  home.stateVersion = "24.05";
}
