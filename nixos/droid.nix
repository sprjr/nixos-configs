{ pkgs, ... }:

{
  environment.packages = [ pkgs.git ];

  user.shell = "${pkgs.fish}/bin/fish";

  home-manager.config = ../home/droid-home.nix;
  home-manager.useGlobalPkgs = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
    sandbox = false
  '';

  system.stateVersion = "24.05";
}
