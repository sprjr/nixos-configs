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

  # Hyprland binds portal shortcuts only via an explicit global bind; the recorded key is ignored.
  wayland.windowManager.hyprland.settings.bind = [
    "SHIFT, Page_Down, global, anomaly.hex:dictation"
  ];
}
