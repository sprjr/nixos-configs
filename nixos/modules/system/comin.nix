{ config, pkgs, ... }:

{
  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/sprjr/nixos-configs.git";
      branches.main.name = "main";
      poller.period = 60;
    }];
    externalDiff.enable = true;
    hostname = config.networking.hostName;
  };
  systemd.services.comin.environment = {
    NIXOS_REBUILD_FLAGS = "--impure";
  };
}
