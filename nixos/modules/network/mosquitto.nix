{ config, pkgs, lib, ... }:

{
  services.mosquitto = {
    enable = true;
    package = pkgs.mosquitto;
    persistence = true;
    listeners = [
      {
        acl = [ "pattern readwrite #" ];
	omitPasswordAuth = true; # change later TODO
	settings.allow_anonymous = true;
      }
    ];
  };

  networks.firewall = {
    enable = true;
    allowedTCPPorts = [ 1883 ];
  };
}
