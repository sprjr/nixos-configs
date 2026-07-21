{ config, pkgs, ... }:

let
  # Session list from the display-manager registry, minus the plain (non-UWSM) Hyprland entry.
  # programs.hyprland.withUWSM registers both hyprland.desktop and hyprland-uwsm.desktop; the
  # plain one never activates graphical-session.target (HM systemd integration is off), leaving
  # a session without wallpaper daemon, timers, or working portals if picked at the greeter.
  sessions = pkgs.runCommand "filtered-wayland-sessions" { } ''
    mkdir -p $out
    for f in ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions/*.desktop; do
      [ "$(basename "$f")" = "hyprland.desktop" ] && continue
      ln -s "$f" "$out/$(basename "$f")"
    done
  '';
in
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${sessions}";
      user = "greeter";
    };
  };

  # Prevents TTY garbage output appearing over the greeter on startup.
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
