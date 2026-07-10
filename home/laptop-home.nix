{
  config,
  pkgs,
  home-manager,
  ...
}:

{
  # Modules
  imports = [
    #   ./linux/desktop_environments/gnome.nix
    ./modules/general/packages.nix
    ./modules/tools/alacritty.nix
    ./modules/tools/claude.nix
    ./modules/tools/opencode.nix
    ./modules/tools/ghostty.nix
    ./modules/tools/neovim.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/colors.nix
    ./modules/user-space/cosmic/cosmic.nix
    ./modules/user-space/hyprland
    ./modules/tools/helix/config.nix
    ./modules/tools/helix/languages.nix
    ./modules/user-space/shell.nix
    ./modules/user-space/zellij/zellij-layout.nix
    ./modules/user-space/zellij/zellij-config.nix
  ];

  # Enable Cosmic
  patrick.home.cosmic = true;

  # Independent, login-selectable Hyprland session (additive to COSMIC). Session daemons
  # only run inside Hyprland, so this stays dormant under COSMIC. Selectable only on hosts
  # whose flake entry also imports nixos/modules/desktop/hyprland.nix.
  patrick.home.hyprland = {
    enable = true;
    battery = true;
    formFactor = "laptop";
    # Internal panel at exact 1.2 scale (240/200 — no fractional-scale snapping). External
    # outputs stay auto (~1.0) via the fallback line, so docking is unaffected.
    monitors = [
      "eDP-1,preferred,auto,1.2"
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
