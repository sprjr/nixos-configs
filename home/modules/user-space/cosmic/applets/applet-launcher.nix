{ pkgs, lib, config, cosmicOverlay, ... }:

let
  cosmicPkgs = pkgs.extend cosmicOverlay;

  applet = cosmicPkgs.rustPlatform.buildRustPackage {
    pname = "cosmic-applet-launcher";
    version = "0.1.0";
    src = ../pkgs/cosmic-applets;
    cargoLock.lockFile = ../pkgs/cosmic-applets/Cargo.lock;
    cargoBuildFlags = [ "-p" "applet-launcher" ];

    nativeBuildInputs = with cosmicPkgs; [ pkg-config just libcosmicAppHook ];
    buildInputs = with cosmicPkgs; [ wayland libxkbcommon mesa ];
    LD_LIBRARY_PATH = lib.makeLibraryPath (with cosmicPkgs; [ wayland libxkbcommon mesa ]);
  };

  shortcuts = [
    { label = "Terminal";	command = "cosmic-term";	args = []; }
    { label = "Files";		command = "cosmic-files";	args = []; }
    { label = "Htop";		command = "cosmic-term";	args = [ "---" "htop" ]; }
    { label = "Suspect";	command = "systemctl";		args = [ "suspend" ]; }
  ];

  shortcutsRon = builtins.toJSON shortcuts;
in
{
  home.packages = [ applet ];

  xdg.dataFile."applications/cosmic-applet-launcher.desktop".text = ''
    [Desktop Entry]
    Name=Launcher
    Type=Application
    Exec=${applet}/bin/cosmic-applet-launcher
    Icon=preferences-system-symbolic
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=4
  '';
  xdg.configFile."com.example.cosmic-applet-launcher/v1/shortcuts".text = shortcutsRon;
}
