{
  description = "AGS (GTK4) control center, hardware monitor, keybind sheet and KDE Connect phone panel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ags, ... }:
    {
      # Bundles the upstream ags home-manager module; import module.nix directly if you already import it.
      homeManagerModules.default = {
        imports = [
          ags.homeManagerModules.default
          (import ./module.nix { inherit ags; })
        ];
      };
    };
}
