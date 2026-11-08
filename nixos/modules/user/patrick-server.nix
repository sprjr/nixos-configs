{
  config,
  pkgs,
  lib,
  sops-nix,
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
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.dconf.enable = true;

  home-manager = {
    extraSpecialArgs = {
      configRoot = "/home/patrick/.nixos/nixos-configs";
    };
    useGlobalPkgs = true;
    users.patrick = {
      imports = [
        sops-nix.homeManagerModules.sops
        ../../../home/server-home.nix
      ];
    };
  };
}
