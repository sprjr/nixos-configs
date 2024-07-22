{ config, pkgs, lib, home-manager, nur, ... }:


let
  hostname = "seair";
  username = "patrick";
in {
  imports = [
    ../home/macos/settings.nix
  ];
  # Define user settings
  users.users.${username} = import ../roles/user.nix { inherit config; inherit pkgs; };

  # Set home-manager configs for username
 #home-manager.users.${username} = import ../roles/home-manager/user.nix;

  # Set hostname
  networking.hostName = "${hostname}";

  # Always show menu bar on M2 Macbook Air 
 #system.defaults.NSGlobalDomain._HIHideMenuBar = lib.mkForce false;

  system.stateVersion = 4;
}
