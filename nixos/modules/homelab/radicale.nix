{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops.secrets."radicale/htpasswd" = {
    owner = "radicale";
    mode = "0400";
  };

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "0.0.0.0:5232" ];
      auth = {
        type = "htpasswd";
        htpasswd_filename = config.sops.secrets."radicale/htpasswd".path;
        htpasswd_encryption = "bcrypt";
      };
      storage.filesystem_folder = "/var/lib/radicale/collections";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5232 ];
}
