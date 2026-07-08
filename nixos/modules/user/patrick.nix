{
  config,
  pkgs,
  lib,
  home-manager,
  sops-nix,
  dark-wallpaper-laptop,
  dark-wallpaper-2,
  dark-wallpaper-3,
  dark-wallpaper-4,
  dark-wallpaper-5,
  ...
}:

{
  users.users.patrick = {
    isNormalUser = true;
    description = "Patrick";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYxyYpBB8K35/1+c22hBDV6mQFkqvxJeBC/SWs8Yyh+ patrick@macnnix"
    ];
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "dialout"
    ];
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
      hyprlandWallpapers = [
        dark-wallpaper-laptop
        dark-wallpaper-2
        dark-wallpaper-3
        dark-wallpaper-4
        dark-wallpaper-5
      ];
      configRoot = "/home/patrick/.nixos/nixos-configs";
    };
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        sops-nix.homeManagerModules.sops
        ../../../home/laptop-home.nix
      ];
    };
  };
}
