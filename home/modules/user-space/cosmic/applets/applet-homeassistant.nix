{ pkgs, lib, config, ... }:

let
  applet = pkgs.rustPlatform.buildRustPackage {
    pname = "cosmic-applet-homeassistant";
    version = "0.1.0";
    src = ../pkgs/cosmic-applets;
    cargoLock.lockFile = ../pkgs/cosmic-applets/Cargo.lock;
    cargoBuildFlags = [ "-p" "applet-homeassistant" ];

    nativeBuildInputs = with pkgs; [ pkg-config ];
    buildInputs = (with pkgs; [ libcosmic wayland libxkbcommon mesa openssl ]);
  };
in
{
  home.packages = [ applet ];
  sops.secrets.ha_token = {
    sopsFile = /home/patrick/.nixos/nixos-configs/sops-nix/sops.yaml;
    path = "${config.xdg.configHome}/sops-secrets/ha_token";
  };

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
