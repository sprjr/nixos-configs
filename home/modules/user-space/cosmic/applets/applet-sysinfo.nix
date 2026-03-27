{ pkgs, lib, ... }:

let
  applet = pkgs.rustPlatform.buildRustPackage {
    pname = "cosmic-applet-sysinfo";
    version = "0.1.0";
    src = ../pkgs/cosmic-applets;
    cargoLock.lockFile = ../pkgs/cosmic-applets/Cargo.lock;
    cargoBuildFlags = [ "-p"  "applet-sysinfo" ];

    nativeBuildInputs = with pkgs; [
      pkg-config
      just
    ];

    buildInputs = with pkgs; [
      libcosmic
      wayland
      libxkbcommon
      mesa
    ];

    LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [ wayland libxkbcommon mesa ]);
  };

  desktopEntry = ''
    [Desktop Entry]
    Name=System Info
    Type=Application
    Exec=${applet}/bin/cosmic-applet-sysinfo
    Icon=utilities-system-monitor-symbolic
    NoDisplay=True
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=5
  '';
in
{
  home.packages = [ applet ];
  xdg.dataFile."applications/cosmic-applet-sysinfo.desktop".text = desktopEntry;
}
