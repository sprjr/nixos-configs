{
  config,
  pkgs,
  lib,
  home-manager,
  ...
}:

{
  # Modules
  imports = [
    ./modules/user-space/colors.nix
    ./modules/tools/claude.nix
    ./modules/tools/helix/config.nix
    ./modules/tools/helix/languages.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/shell.nix
    ./modules/user-space/zellij/zellij-layout-darwin.nix
    ./modules/user-space/zellij/zellij-config.nix
    ./modules/tools/ghostty.nix
    ./modules/tools/neovim.nix
    ./modules/tools/obsidian-daily-carry.nix
    ./modules/general/packages.nix
    ./modules/general/workstation-packages.nix
  ];

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "sprjr";
        email = "patrick@rawlinson.ws";
      };
    };
  };

  home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/patrick" else "/home/patrick";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  programs.zsh.profileExtra = ''
    eval "$(/opt/homebrew/bin/brew shellenv)"
  '';

  home.activation.createObsidianVault = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/Documents/Obsidian/Vaults"
  '';

  # Ignore patterns for the claude-config folder; the folder itself is accepted from the hub in the GUI
  home.activation.claudeStignore = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.claude"
    install -m 0644 ${pkgs.writeText "claude-config.stignore" (import ../nixos/modules/homelab/claude-stignore.nix)} "$HOME/.claude/.stignore"
  '';

  services.syncthing.enable = true;

  home.stateVersion = "24.05";
}
