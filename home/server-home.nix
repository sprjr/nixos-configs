{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./modules/tools/claude.nix
    ./modules/tools/opencode.nix
    ./modules/tools/neovim.nix
    ./modules/tools/helix/config.nix
    ./modules/tools/helix/languages.nix
    ./modules/user-space/bat.nix
    ./modules/user-space/colors.nix
    ./modules/user-space/shell.nix
    ./modules/user-space/zellij/zellij-layout.nix
    ./modules/user-space/zellij/zellij-config.nix
  ];

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
    homeDirectory = "/home/patrick";
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
