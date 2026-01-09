{ config, pkgs, lib, ... }:

{
  services.mosquitto = {
    enable = true;
    package = pkgs.mosquitto;
    persistence = true;
  };
}
