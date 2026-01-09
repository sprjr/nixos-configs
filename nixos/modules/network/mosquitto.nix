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

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 1883 ];
  };
}
