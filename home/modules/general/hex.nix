{ hex, ... }:

{
  imports = [ hex.homeManagerModules.hex ];

  programs.hex = {
    enable = true;
    autostart = true;
    systemdTarget = "hyprland-session.target";
    shortcut = "option+space";
    model = "parakeet_v3";
    installModel = true;
  };
}
