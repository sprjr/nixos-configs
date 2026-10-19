{ stylix, ... }:

# Same palette, fonts, and terminal opacity as the NixOS desktop hosts. Reaches
# home-manager.users.* through Stylix's homeManagerIntegration.
{
  imports = [
    stylix.darwinModules.stylix
    ../../nixos/modules/desktop/stylix-common.nix
  ];
}
