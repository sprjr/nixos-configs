{ lib, pkgs, ... }:

{
  home.packages = [ pkgs.nuclei ];

  imports =
    lib.optional pkgs.stdenv.hostPlatform.isLinux ./nuclei-systemd.nix
    ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin ./nuclei-launchd.nix;
}
