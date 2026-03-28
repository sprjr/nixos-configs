{ nixos-cosmic, ... }:

{
  imports = [ nixos-cosmic.nixosModules.default ];

  nixpkgs.overlays = [
    nixos-cosmic.overlays.default
    (final: prev: {
      cosmic-edit = prev.cosmic-edit.overrideAttrs (_: {
        src = final.fetchFromGitHub {
          owner = "pop-os";
          repo = "cosmic-edit";
          rev = prev.cosmic-edit.src.rev;
          hash = "sha256-GN1Zts+v3ARcrkN+ZkMUSGNOAlIhXSYWRtWAyqUfUrY=";
        };
      });
    })
  ];

  nix.settings = {
    substituters = [ "https://cosmic.cachix.org" ];
    trusted-public-keys = [ "cosmic.cachix.org-1:Dya6IxT5r5k6SJOsGKFGMEMQDcWlBoAN1JgaoL/hMKE=" ];
  };
}
