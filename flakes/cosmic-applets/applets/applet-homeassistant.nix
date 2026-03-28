{ pkgs, cosmic-applets, ... }:

let
  applet = cosmic-applets.packages.${pkgs.system}.applet-homeassistant;
in
{
  home.packages = [ applet ];

  xdg.dataFile."applications/cosmic-applet-homeassistant.desktop".text = ''
    [Desktop Entry]
    Name=System Info
    Type=Application
    Exec=${applet}/bin/applet-homeassistant
    Icon=utilities-system-monitor-symbolic
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=5
  '';
}
