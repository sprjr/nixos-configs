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
    extnixos-rebuild-args = [ "--impure" ];
    hostname = config.networking.hostName;
  };
}
