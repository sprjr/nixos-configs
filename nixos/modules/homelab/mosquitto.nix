{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops.secrets."mosquitto/homeassistant-password" = {
    owner = "mosquitto";
    mode = "0400";
  };

  sops.secrets."mosquitto/frigate-password" = {
    owner = "mosquitto";
    mode = "0400";
  };

  sops.secrets."mosquitto/hermes-password" = {
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
          passwordFile = config.sops.secrets."mosquitto/homeassistant-password".path;
        };
        users.frigate = {
          acl = [ "readwrite frigate/#" ];
          passwordFile = config.sops.secrets."mosquitto/frigate-password".path;
        };
        users.hermes = {
          acl = [ "read frigate/#" ];
          passwordFile = config.sops.secrets."mosquitto/hermes-password".path;
        };
        settings.allow_anonymous = false;
      }
    ];
  };

  systemd.services.mosquitto = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 1883 ];
  };
}
