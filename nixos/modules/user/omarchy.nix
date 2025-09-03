{ configs, home-manager, pkgs, ... }:

{
  config.nix.omarchyOptions = {
    full_name = "patrick";
    email_address = "patrick@rawlinson.ws";
    theme = "nord";
    primary_font = "nerd-fonts.hack";
    monitors = [ "eDP-1" "HDMI-A-1" ];
    scale = 2;
  };
}
