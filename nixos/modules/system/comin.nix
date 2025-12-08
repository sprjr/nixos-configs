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
    extraOptions = [ "--impure" ];
    hostname = config.networking.hostName;
  };
}
