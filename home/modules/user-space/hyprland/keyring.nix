{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Signal (Electron) defaults to the plaintext basic_text keyring under Hyprland because Chromium
# can't map XDG_CURRENT_DESKTOP=Hyprland to a backend. Pin it to the freedesktop Secret Service
# (gnome-libsecret) — backed by gnome-keyring under Hyprland (see nixos/modules/desktop/hyprland.nix
# + the SDDM PAM unlock) and by kwallet under KDE, so one flag works in both sessions.
#
# A binary wrapper (not just a desktop-entry override) is used so the flag applies on EVERY launch
# path: the app launcher, Signal's self-written ~/.config/autostart entry, and the terminal.
#
# One-time cost: the first launch off the old native kwallet6 store, Signal cannot decrypt its DB
# key and must be re-linked (local history re-syncs from the phone). See the module docs / handoff.
let
  cfg = config.patrick.home.hyprland;
  signal = pkgs.writeShellScriptBin "signal-desktop" ''
    exec ${pkgs.signal-desktop}/bin/signal-desktop --password-store=gnome-libsecret "$@"
  '';
in
{
  config = mkIf (cfg.enable && cfg.signalGnomeKeyring) {
    # Wrapper shadows the system signal-desktop on the user PATH.
    home.packages = [ (lib.hiPrio signal) ];

    xdg.desktopEntries."signal-desktop" = {
      name = "Signal";
      genericName = "Private Messenger";
      comment = "Private messaging from your desktop";
      # Bare name resolves to the wrapper via PATH.
      exec = "signal-desktop %U";
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
