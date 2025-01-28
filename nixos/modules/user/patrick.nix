{ config, pkgs, lib, home-manager, ... }:

{
  users.users.patrick = {
    isNormalUser = true;
    description = "Patrick";
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [
      kdePackages.kate
      (wineWowPackages.full.override {
        wineRelease = "staging";
        mingwSupport = true;
      })
      winetricks
    ];
  };

  # Home-Manager
  home-manager = {
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        ../../../home/home.nix
      ];
    };
  };
}
