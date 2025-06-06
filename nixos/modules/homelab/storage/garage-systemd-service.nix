{ config, pkgs, ... }:

{
  systemd.services.garage = {
    description = "S3 Garage Object Store";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.garage}/bin/garage server -c /home/patrick/garage/garage.toml";
      Restart = "on-failure";
      User = "garage";
      Group = "garage";
      WorkingDirectory = "/var/lib/garage";
    };
  };

  users.users.garage = {
    isSystemUser = true;
    group = "garage";
    home = "/var/lib/garage";
  };

  users.groups.garage = {};

  # Open needed ports
  networking.firewall.allowedTCPPorts = [ 3900 3901 3902 3903 3904 ];
}
