{
  pkgs,
  osConfig ? { },
  lib,
  ...
}:

let
  isServer = (osConfig.networking.hostName or "") == "shikisha";
  workstationPackages =
    with pkgs;
    [
      mapscii
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      rustnet
    ];
in
{
  # Workstation-only packages; never import from a server profile.
  home.packages = lib.optionals (!isServer) workstationPackages;
}
