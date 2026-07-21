{
  pkgs,
  whale-wallpaper,
  ...
}:
{
  users.users.whale = {
    isNormalUser = true;
    description = "Whale";
    extraGroups = [
      "networkmanager"
      "audio"
    ];
    shell = pkgs.bash;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit whale-wallpaper;
    };
    users.whale = {
      imports = [
        ../../../home/whale-home.nix
      ];
    };
  };
}
