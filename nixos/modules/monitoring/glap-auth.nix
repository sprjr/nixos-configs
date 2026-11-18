{
  lib,
  config,
  ...
}:

{
  sops.secrets."glap/api-token" = {
    owner = "root";
    mode = "0400";
  };

  services.caddy = {
    enable = true;
    virtualHosts."http://:8443".extraConfig = ''
      @auth_header {
        header Authorization "Bearer {$GLAP_TOKEN}"
      }
      route {
        handle @auth_header {
          handle_path /prometheus/* {
            reverse_proxy 127.0.0.1:9090
          }
          handle_path /loki/* {
            reverse_proxy 127.0.0.1:3100
          }
        }
        respond 401
      }
    '';
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets."glap/api-token".path;
}
