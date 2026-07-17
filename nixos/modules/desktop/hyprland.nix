{ pkgs, ... }:

# Independent, login-selectable Hyprland session. Additive to cosmic.nix / gnome.nix —
# enabling this does not disturb an existing desktop. programs.hyprland.enable installs
# the compositor and registers the Wayland session desktop file, so Hyprland appears in
# the host's existing greeter (cosmic-greeter / GDM) picker.
#
# This module deliberately does NOT configure a greeter, pipewire, or networkmanager —
# those come from the host's primary desktop module (e.g. cosmic.nix) or host config. A
# host that wires Hyprland as its ONLY desktop must provide a greeter + audio itself.
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # polkit daemon; the authentication agent itself is launched from the Hyprland home
  # autostart (exec-once in the home module).
  security.polkit.enable = true;

  # Allow hyprlock to authenticate via PAM (password + fingerprint where fprintd is present).
  security.pam.services.hyprlock = { };

  # Secret service for the Hyprland session (Electron/Signal use --password-store=gnome-libsecret).
  # Installs the DBus-activated org.freedesktop.secrets provider so libsecret clients work when no
  # KDE kwallet is present. Under KDE, kwallet already owns the name, so this stays dormant there.
  services.gnome.gnome-keyring.enable = true;
}
