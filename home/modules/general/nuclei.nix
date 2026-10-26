{ pkgs, ... }:

{
  home.packages = [ pkgs.nuclei ];

  # Static imports: gating on pkgs here queries config and recurses under NixOS-embedded home-manager.
  imports = [
    ./nuclei-systemd.nix
    ./nuclei-launchd.nix
  ];
}
