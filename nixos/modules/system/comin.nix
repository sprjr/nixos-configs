{ config, pkgs, ... }:

{
  services.comin = {
    enable = true;
    hostname = config.networking.hostName;
    remotes = [{
      name = "origin";
      url = "https://github.com/sprjr/nixos-configs.git";
      branches.main.name = "main";
      poller.period = 60;
    }];
  };
}
