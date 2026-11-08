{ pkgs, ... }:
{
  # Qt 6.12 uic rejects widget class names with a leading "::"; upstream fixed it
  # in google/mozc@29c082a, not yet in 2.30.5544.102.
  nixpkgs.overlays = [
    (final: prev: {
      mozc = prev.mozc.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/gui/dictionary_tool/dictionary_tool.ui \
            --replace-fail "::mozc::gui::DictionaryContentTableWidget" "mozc::gui::DictionaryContentTableWidget"
        '';
      });
    })
  ];

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
