{
  config,
  pkgs,
  home-manager,
  ...
}:

{
  # Full desktop/workstation package set: shared CLI tools + GUI applications.
  imports = [
    ./cli-packages.nix
    ./desktop-packages.nix
  ];
}
