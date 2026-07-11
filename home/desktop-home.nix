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
    formFactor = "desktop";
    gpu = "nvidia";
    signalGnomeKeyring = true;
    gaming.enable = true;
    # Explicit left-to-right layout: DP-2 (4K) left, DP-1 (1440p165) center, DP-3 (4K) right.
    # Offsets are the running sum of each output's real logical width (verified via
    # `hyprctl monitors all`): DP-2 @1.6667 snaps to 240/144 → logical 2304, DP-1 @1 → 2560,
    # DP-3 @1.6 → 2400. So DP-1 sits at DP-2's edge (2304) and DP-3 at 2304+2560 (4864).
    # `auto-right` was tried and rejected: Hyprland resolves it in enumeration order (DP-3 before
    # DP-1), which put the center panel on the far right. Explicit offsets keep the physical order.
    monitors = [
      "DP-2,3840x2160@60,0x0,1.6667"
      "DP-1,2560x1440@165,2304x0,1"
      "DP-3,3840x2160@60,4864x0,1.6"
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
