{ config, lib, pkgs, ... }:

{
  boot.binfmt.emulatedSystems = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [ "aarch64-linux" ];
}
