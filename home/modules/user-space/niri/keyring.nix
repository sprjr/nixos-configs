{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Signal gnome-libsecret wrapper: Electron can't detect the backend under Niri.
let
  cfg = config.patrick.home.niri;
  signal = pkgs.writeShellScriptBin "signal-desktop" ''
    exec ${pkgs.signal-desktop}/bin/signal-desktop --password-store=gnome-libsecret "$@"
  '';
in
{
  config = mkIf (cfg.enable && cfg.signalGnomeKeyring) {
    home.packages = [ (lib.hiPrio signal) ];

    xdg.desktopEntries."signal-desktop" = {
      name = "Signal";
      genericName = "Private Messenger";
      comment = "Private messaging from your desktop";
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
