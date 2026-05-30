{ config, lib, pkgs, home-manager, ... }:

let
  cfg = config.services.desktopManager.plasma6;

  kwin-effects-glass = pkgs.stdenv.mkDerivation {
    pname = "kwin-effects-glass";
    version = "1.6.4";
    src = pkgs.fetchFromGitHub {
      owner = "4v3ngR";
      repo = "kwin-effects-glass";
      rev = "v1.6.4";
      hash = "sha256-Mb/Ha1P/sSqbJ/a1OupXdJt9oOCdXffHOoZGbpc2568=";
    };
    nativeBuildInputs = with pkgs; [
      cmake
      kdePackages.extra-cmake-modules
      pkg-config
    ];
    buildInputs = with pkgs.kdePackages; [
      kwin
      kdecoration
      kcmutils
      ki18n
      kguiaddons
      qtbase
      qtmultimedia
    ];
  };

  glass-theme = pkgs.stdenv.mkDerivation {
    pname = "glass-kde-theme";
    version = "unstable-2025-05-29";
    src = pkgs.fetchFromGitHub {
      owner = "4v3ngR";
      repo = "Glass";
      rev = "2ec67bf2d28094d629bf3fe9bc55c7a8a393cfb1";
      hash = "sha256-k7pb+ahL8g4WlAustxzkDdewOBRP3HNg9FK4WZ/Of2c=";
    };
    nativeBuildInputs = with pkgs; [
      cmake
      kdePackages.extra-cmake-modules
      pkg-config
    ];
    buildInputs = with pkgs.kdePackages; [
      qtbase
      kcoreaddons
      kconfig
      kguiaddons
      ki18n
      kiconthemes
      kwindowsystem
      kcolorscheme
      kcmutils
      kdecoration
      frameworkintegration
      qtdeclarative
    ];
  };
in

lib.mkIf cfg.enable {
  environment.systemPackages = [
    kwin-effects-glass
    glass-theme
  ];

  home-manager.users.patrick.home.activation.kdeGlassConfig =
    home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group Effect-blurplus --key Brightness 0.9
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group Effect-blurplus --key Contrast 1.1
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group Effect-blurplus --key Saturation 1.0
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group Effect-blurplus --key BlurStrength 3
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group Effect-blurplus --key TintColor '"#00000000"'
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group Effect-blurplus --key GlowColor '"#1080D0FF"'
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group Effect-blurplus --key EdgeLighting true
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file konsolerc --group "Desktop Entry" --key DefaultProfile dark.profile
    '';
}
