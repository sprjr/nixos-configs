{ ... }:

{
  imports = [
    ./syncthing-client.nix
    ../system/sops.nix
  ];

  services.syncthing-client = {
    enable = true;
    vaultPath = "/home/patrick/Documents/Obsidian/Vaults";
  };
}
