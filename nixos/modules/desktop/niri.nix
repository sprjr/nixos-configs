{ pkgs, ... }:

# Independent, login-selectable Niri session. Additive to cosmic.nix / gnome.nix /
# hyprland.nix — enabling this does not disturb an existing desktop. programs.niri.enable
# installs the compositor and registers the Wayland session desktop file, so Niri appears
# in the host's existing greeter (greetd/tuigreet) picker.
#
# This module deliberately does NOT configure a greeter, pipewire, or networkmanager —
# those come from the host's primary desktop module or host config.
{
  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  security.polkit.enable = true;

  # Allow swaylock to authenticate via PAM (password + fingerprint where fprintd is present).
  security.pam.services.swaylock = { };

  # Secret service for the Niri session (Electron/Signal use --password-store=gnome-libsecret).
  services.gnome.gnome-keyring.enable = true;

  # XWayland via xwayland-satellite (Niri has no built-in XWayland).
  environment.systemPackages = [ pkgs.xwayland-satellite ];
}
