{ config, pkgs, ... }:

{  
  virtualisation.oci-containers = {
    backend = "docker";
    containers.homeassistant = {
      volumes = [ "./app_data/homeassistant:/config" ];
      environment.TZ = "America/Denver";
      image = "ghcr.io/home-assistant/home-assistant:latest";
      extraOptions = [ 
        "--network=host" 
      ];
    };
  };
}
