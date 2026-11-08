{ pkgs, cosmic-applets, ... }:

let
  applet = cosmic-applets.packages.${pkgs.system}.applet-launcher;
in
{
  home.packages = [ applet ];

  xdg.dataFile."applications/cosmic-applet-launcher.desktop".text = ''
    [Desktop Entry]
    Name=System Info
    Type=Application
    Exec=${applet}/bin/applet-launcher
    Icon=utilities-system-monitor-symbolic
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=5
  '';
}
