{ config, lib, pkgs, ... }:

{
  # -duc also disables -ut in 3.11.1; leave it off this command
  systemd.user.services.nuclei-templates = {
    Unit.Description = "Update nuclei templates";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.nuclei}/bin/nuclei -ut -ud ${config.home.homeDirectory}/nuclei-templates";
    };
  };

  systemd.user.timers.nuclei-templates = {
    Unit.Description = "Daily nuclei template update";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Seed templates on fresh hosts; the timer does not fire until its first calendar slot.
  home.activation.nucleiTemplates = lib.mkIf pkgs.stdenv.isLinux (
    lib.hm.dag.entryAfter [ "writeBoundary" "reloadSystemd" ] ''
      if [ ! -d "${config.home.homeDirectory}/nuclei-templates" ]; then
        run ${pkgs.systemd}/bin/systemctl --user start --no-block nuclei-templates.service || true
      fi
    ''
  );
}
