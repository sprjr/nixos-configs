{
  pkgs,
  whale-wallpaper,
  ...
}:
{
  users.users.seagull = {
    isNormalUser = true;
    description = "Seagull";
    extraGroups = [
      "networkmanager"
      "audio"
    ];
    shell = pkgs.bash;
    hashedPasswordFile = "/var/lib/secrets/seagull-user.hash";
  };

  home-manager = {
    extraSpecialArgs = {
      inherit whale-wallpaper;
    };
    users.seagull = {
      imports = [
        ../../../home/seagull-home.nix
      ];
    };
  };
}
