{ config, pkgs, ... }:

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
}
