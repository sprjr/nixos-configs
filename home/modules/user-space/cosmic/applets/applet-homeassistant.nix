{ pkgs, lib, config, cosmicOverlay, ... }:

let
  cosmicPkgs = pkgs.extend cosmicOverlay;

  applet = cosmicPkgs.rustPlatform.buildRustPackage {
    pname = "cosmic-applet-homeassistant";
    version = "0.1.0";
    src = ../pkgs/cosmic-applets;
    cargoLock.lockFile = ../pkgs/cosmic-applets/Cargo.lock;
    cargoBuildFlags = [ "-p" "applet-homeassistant" ];

    nativeBuildInputs = with cosmicPkgs; [ pkg-config just libcosmicAppHook ];
    buildInputs = (with cosmicPkgs; [ wayland libxkbcommon mesa openssl ]);
  };
in
{
  home.packages = [ applet ];

  xdg.dataFile."applications/cosmic-applet-homeassistant.desktop".text = ''
    [Desktop Entry]
    Name=Home Assistant
    Type=Application
    Exec=${applet}/bin/cosmic-applet-homeassistant
    Icon=network-wireless-symbolic
    NoDisplay=true
    X-CosmicApplet=true
    X-CosmicHoverPopup=Auto
    X-OverflowPriority=3
  '';

  xdg.configFile."com.example.cosmic-applet-homeassistant/v1/base_url".text =
    "https://shikisha:8123";
  xdg.configFile."com.example.cosmic-applet.homeassistant/v1/token_path".text =
    "${config.xdg.configHome}/sops-secrets/ha_token";
}
