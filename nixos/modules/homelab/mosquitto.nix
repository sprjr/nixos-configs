{ config, pkgs, lib, ... }:

{
  sops.secrets."mosquitto/mosquitto_password" = {
    owner = "mosquitto";
    mode = "0400";
  };

  services.mosquitto = {
    enable = true;
    package = pkgs.mosquitto;
    persistence = true;
    listeners = [
      {
        port = 1883;
        users.homeassistant = {
          acl = [ "readwrite #" ];
          passwordFile = config.sops.secrets."mosquitto/mosquitto_password".path;
        };
        settings.allow_anonymous = false;
      }
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 1883 ];
  };
}
