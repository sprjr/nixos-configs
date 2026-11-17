{ pkgs, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    # Wayland text-input-v3 frontend. Also suppresses the module's GTK_IM_MODULE /
    # QT_IM_MODULE exports, which fcitx5 warns about under Hyprland. XMODIFIERS stays
    # set for XWayland clients.
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];
}
