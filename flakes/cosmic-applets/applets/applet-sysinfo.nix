{ pkgs, cosmic-applets, ... }:

let
  applet = cosmic-applets.packages.${pkgs.system}.applet-sysinfo;
in
{
  home.packages = [ applet ];

  xdg.dataFile."applications/cosmic-applet-sysinfo.desktop".text = ''
    [Desktop Entry]
    Name=System Info
    Type=Application
    Exec=${applet}/bin/applet-sysinfo
    Icon=utilities-system-monitor-symbolic
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=5
  '';
}
