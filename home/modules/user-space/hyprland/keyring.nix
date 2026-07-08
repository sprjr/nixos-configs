{
  config,
  lib,
  ...
}:

with lib;

# Signal (and other Electron apps) default to the plaintext basic_text keyring under Hyprland
# because Chromium can't map XDG_CURRENT_DESKTOP=Hyprland to a backend. Pin it to the freedesktop
# Secret Service (gnome-libsecret), which is backed by gnome-keyring under Hyprland (see the system
# module) and by kwallet under KDE — so one flag works in both sessions. Signal needs a one-time
# re-link the first time it switches off the old native kwallet6 store.
#
# This shadows the packaged signal-desktop.desktop via ~/.local/share/applications (earlier in
# XDG_DATA_DIRS). Harmless where Signal isn't installed (a launcher entry to a missing binary).
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf cfg.enable {
    xdg.desktopEntries."signal-desktop" = {
      name = "Signal";
      genericName = "Private Messenger";
      comment = "Private messaging from your desktop";
      exec = "signal-desktop --password-store=gnome-libsecret %U";
      icon = "signal-desktop";
      terminal = false;
      type = "Application";
      startupNotify = true;
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
      mimeType = [
        "x-scheme-handler/sgnl"
        "x-scheme-handler/signalcaptcha"
      ];
    };
  };
}
