{ config, pkgs, home-manager, ... }:

{
  # Modules
  imports = [
    ./modules/user-space/zellij/zellij-layout.nix
    ./modules/user-space/zellij/zellij-config.nix
  ];
}
