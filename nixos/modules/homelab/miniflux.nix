{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "rss.rawliyosh.com";
  port = 8989;
  dataDir = "/var/lib/miniflux";
in
{
  sops.secrets."miniflux/admin-password" = { };
  sops.secrets."miniflux/oauth-client-id" = { };
  sops.secrets."miniflux/oauth-client-secret" = { };

  sops.templates."miniflux-admin" = {
    mode = "0400";
    content = ''
      ADMIN_USERNAME=admin
      ADMIN_PASSWORD=${config.sops.placeholder."miniflux/admin-password"}
    '';
  };

  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;
    adminCredentialsFile = config.sops.templates."miniflux-admin".path;
    config = {
      LISTEN_ADDR = "0.0.0.0:${toString port}";
      BASE_URL = "https://${domain}";
      CREATE_ADMIN = 1;
      ADMIN_USERNAME = "admin";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.rawliyosh.com/application/o/miniflux/";
      OAUTH2_CLIENT_ID_FILE = config.sops.secrets."miniflux/oauth-client-id".path;
      OAUTH2_CLIENT_SECRET_FILE = config.sops.secrets."miniflux/oauth-client-secret".path;
      OAUTH2_REDIRECT_URL = "https://${domain}/oauth2/callback";
      OAUTH2_USER_CREATION = 1;
      OAUTH2_OIDC_PROVIDER_NAME = "Authentik";
    };
  };

  systemd.services.miniflux = {
    after = [ "sops-secrets-rendered.service" ];
    requires = [ "sops-secrets-rendered.service" ];
    serviceConfig = {
      StateDirectory = "miniflux";
      WorkingDirectory = dataDir;
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
}
