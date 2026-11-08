{
  pkgs,
  osConfig ? { },
  lib,
  spicetify-nix ? null,
  ...
}:

let
  isServer = (osConfig.networking.hostName or "") == "shikisha";
  spicetify = lib.optionals (spicetify-nix != null) [
    spicetify-nix.packages.${pkgs.stdenv.hostPlatform.system}.nord
  ];
  workstationPackages =
    with pkgs;
    [
      mapscii
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      rustnet
    ]
    ++ spicetify;
in
{
  # Workstation-only packages; never import from a server profile.
  home.packages = lib.optionals (!isServer) workstationPackages;
}
