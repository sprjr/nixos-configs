{ config, pkgs, ... }:

{
  sops.secrets.ha_token = {
    owner = "patrick";
    mode = "0400";
  };
}
