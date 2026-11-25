{
  config,
  pkgs,
  lib,
  home-manager,
  hokum,
  ...
}:

{
  # Modules
  imports = [
    ./linux/desktop_environments/gnome.nix
    ./modules/general/packages.nix
    ./modules/general/workstation-packages.nix
    ./modules/general/hex.nix
    ./modules/tools/alacritty.nix
    ./modules/tools/claude.nix
    ./modules/tools/opencode.nix
    ./modules/tools/t3code.nix
    ./modules/tools/ghostty.nix
    ./modules/tools/neovim.nix
    ./modules/tools/helix/config.nix
    ./modules/tools/helix/languages.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/btop.nix
    ./modules/user-space/colors.nix
    ./modules/user-space/themes/gtk.nix
    ./modules/user-space/hyprland
    ./modules/user-space/shell.nix
    ./modules/user-space/zellij/zellij-layout-desktop.nix
    ./modules/user-space/zellij/zellij-config.nix
  ];

  # Independent, login-selectable Hyprland session (additive to the KDE/GNOME session).
  # seanix: three-monitor layout (fallback line last for hotplug) and the Nvidia session
  # env/GPU widget.
  patrick.home.hyprland = {
    enable = true;
    #shell = "caelestia";
    shell = "native";
    formFactor = "desktop";
    gpu = "nvidia";
    signalGnomeKeyring = true;
    gaming.enable = true;
    ollamaUsage.enable = true;
    # Left to right: DP-3, DP-2, DP-1.
    monitors = [
      "DP-3,3840x2160@60,0x0,1.6"
      "DP-2,2560x1440@165,2400x0,1"
      "DP-1,3840x2160@60,4960x0,1.6"
      "HDMI-A-1,1920x1080@60,auto,1"
      ",preferred,auto,auto"
    ];
    # DP-1/DP-2 hit the 0.57 NVIDIA EINVAL commit loop (zoomed/choppy) on login.
    commitLoopOutputs = [ "DP-1" "DP-2" ];
    # mon-remote: headless streaming workspace; mon-local: restore DPMS + focus.
    streaming = {
      enable = true;
      resolution = "1920x1080@60";
      physicalOutputs = [
        "DP-1"
        "DP-2"
        "DP-3"
      ];
      workspace = 11;
      bigPicture = true;
      primaryOutput = "DP-1";
    };

    notifications.daemon = "hokum";
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
    homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/patrick" else "/home/patrick";
    username = "patrick";
    packages = lib.optional (config.patrick.home.hyprland.notifications.daemon == "hokum")
      hokum.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  programs.caelestia = lib.mkIf (config.patrick.home.hyprland.shell == "caelestia") {
    enable = true;
    systemd.target = "hyprland-session.target";
  };

  home.stateVersion = "24.05";
}
