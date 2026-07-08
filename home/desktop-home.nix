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
    gaming.enable = true;
    # Explicit left-to-right layout: DP-2 (4K) left, DP-1 (1440p165) center, DP-3 (4K) right.
    # DP-2 @1.7 isn't a clean scale — Hyprland can only use scales of the form 240/n (both axes
    # integer) and lands on 240/142 = 1.6901, giving DP-2 a real logical width of 2272 (the old
    # offset assumed 2259, so DP-2 overran DP-1 by ~13px — the cut-off edge). Neighbors sit at that
    # real edge: DP-1 at 2272, DP-3 at 2272+2560=4832. No overlap, no gap.
    # VERIFY with `hyprctl monitors all`: read DP-2's actual `size`/`scale`; if its width isn't 2272,
    # set DP-1's X to that width and DP-3's X to (that width + 2560).
    monitors = [
      "DP-2,3840x2160@60,0x0,1.7"
      "DP-1,2560x1440@165,2272x0,1"
      "DP-3,3840x2160@60,4832x0,1.6"
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
