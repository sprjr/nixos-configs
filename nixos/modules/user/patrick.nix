{ config, pkgs, lib, home-manager, cosmic-applets, nixos-cosmic, dark-wallpaper-laptop, ... }:

{
  users.users.patrick = {
    isNormalUser = true;
    description = "Patrick";
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [
      kdePackages.kate
      (wineWow64Packages.full.override {
        wineRelease = "staging";
        mingwSupport = true;
      })
      winetricks
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # Home-Manager
  home-manager = {
    extraSpecialArgs = {
      inherit cosmic-applets;
      inherit dark-wallpaper-laptop;
      cosmicOverlay = nixos-cosmic.overlays.default;
      configRoot = "/home/patrick/.nixos/nixos-configs";
    };
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        ../../../home/laptop-home.nix
      ];
    };
  };
}
