{ config, pkgs, ... }:

{
  description = "Patrick Rawlinson";
  name = "Patrick Rawlinson";
  shell = pkgs.bash;
  # These packages will only be installed for your user
  # The binaries will be available in the following path: /etc/profiles/per-user/$USER/bin
  packages = [
    pkgs.bash
    pkgs.gcc
    pkgs.git
    pkgs.gnupg
    pkgs.tmux
  ];
}
