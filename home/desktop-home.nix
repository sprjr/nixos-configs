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
    signalGnomeKeyring = true;
    # Left-to-right chain via auto-right: each output's X derives from the previous output's
    # actual (scale-rounded) logical width, so the fractional DP-2 scale can't cause overlap.
    # DP-2 anchors at 0,0; tops align. (Old hardcoded offsets assumed DP-2 was exactly 2259
    # wide, but 3840/1.7 = 2258.82 rounds elsewhere and overran DP-1.)
    monitors = [
      "DP-2,3840x2160@60,0x0,1.7"
      "DP-1,2560x1440@165,auto-right,1"
      "DP-3,3840x2160@60,auto-right,1.6"
      "HDMI-A-1,disable"
      ",preferred,auto,auto"
    ];
    # `mon-remote` (remon): single HDMI streaming head, desktop outputs off — mirrors the old
    # kscreen switch-remote.sh. `mon-local` (lomon) re-applies `monitors` above.
    remoteMonitors = [
      "HDMI-A-1,1920x1080@60,0x0,1"
      "DP-1,disable"
      "DP-2,disable"
      "DP-3,disable"
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
