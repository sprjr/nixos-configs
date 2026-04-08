{
  config,
  pkgs,
  home-manager,
  ...
}:

{
  # Configuration files
  imports = [
    #   ./linux/desktop_environments/gnome.nix
    ./modules/general/packages.nix
    ./modules/tools/alacritty.nix
    ./modules/tools/ghostty.nix
    ./modules/tools/neovim.nix
    ./modules/user-space/bat.nix
    #   ./modules/user-space/btop.nix
    ./modules/user-space/colors.nix
    ./modules/user-space/cosmic/cosmic.nix
    ./modules/tools/helix/config.nix
    ./modules/tools/helix/languages.nix
    ./modules/tools/helix/theme-nord.nix
    ./modules/user-space/shell.nix
    ./modules/user-space/zellij/zellij-layout.nix
    ./modules/user-space/zellij/zellij-config.nix
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

  home.username = "patrick";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/patrick" else "/home/patrick";

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  home.stateVersion = "24.05";
}
