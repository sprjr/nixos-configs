{
  config,
  lib,
  pkgs,
  home-manager,
  ...
}:

let
  cfg = config.services.desktopManager.plasma6;

  glassOS-src = pkgs.fetchFromGitHub {
    owner = "4v3ngR";
    repo = "glassOS";
    rev = "e7c689adda7a8fc4d76d641a55b0f6b8521965c3";
    hash = "sha256-2FkpfJz+Mx6P5hKj6rPFUVaSQeXKzrUkeSgmAr8er5A=";
  };

  kwin-effects-glass = pkgs.stdenv.mkDerivation {
    pname = "kwin-effects-glass";
    version = "2026-05-31";
    dontWrapQtApps = true;
    src = pkgs.fetchFromGitHub {
      owner = "4v3ngR";
      repo = "kwin-effects-glass";
      rev = "20260531-01";
      hash = "sha256-DF5qYLAkYxdwGDTUoWkHoJ0GwgQiv1rtQtR81lhQtc4=";
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
      qttools
    ];
  };

  glass-theme = pkgs.stdenv.mkDerivation {
    pname = "glass-kde-theme";
    version = "unstable-2025-05-29";
    dontWrapQtApps = true;
    cmakeFlags = [ "-DBUILD_QT5=OFF" ];
    src = pkgs.fetchFromGitHub {
      owner = "4v3ngR";
      repo = "Glass";
      rev = "2ec67bf2d28094d629bf3fe9bc55c7a8a393cfb1";
      hash = "sha256-9w3h3GKnBE89gD1mrWaS/88GqgXnW29+9lYbgO1w+xc=";
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

  home-manager.users.patrick = {
    xdg.dataFile = {
      "konsole/Dark.colorscheme".source = "${glassOS-src}/share/konsole/Dark.colorscheme";
      "konsole/dark.profile".source = "${glassOS-src}/share/konsole/dark.profile";
      "color-schemes/GlassDark.colors".source = "${glassOS-src}/share/color-schemes/GlassDark.colors";
      "aurorae/themes/glassOS".source = "${glassOS-src}/share/aurorae/themes/glassOS";
    };

    home.activation.kdeGlassConfig = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
        --file kwinrc --group Plugins --key glassEnabled true
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kdeglobals --group KDE --key widgetStyle Glass
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kdeglobals --group General --key ColorScheme GlassDark
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group "org.kde.kdecoration2" --key library org.kde.glass
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file kwinrc --group "org.kde.kdecoration2" --key theme '""'
      run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
        --file konsolerc --group "Desktop Entry" --key DefaultProfile dark.profile
    '';
  };
}
