{ config, pkgs, lib, home-manager, nixos-cosmic, dark-wallpaper-laptop, ... }:

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
      inherit dark-wallpaper-laptop;
      cosmicOverlay = nixos-cosmic.overlays.default;
    };
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        ../../../home/laptop-home.nix
      ];
    };
  };
}
