{ config, pkgs, home-manager, ... }:

{
  imports = [
    ./modules/user-space/zellij/zellij-layout-darwin.nix
    ./modules/user-space/zellij/zellij-config.nix
  ];
}
