{ config, ... }:

{
  # OIDC_RP_CLIENT_ID, OIDC_RP_CLIENT_SECRET and the remaining LD_* settings
  sops.secrets."linkding/env" = { };

  virtualisation.oci-containers.containers.linkding = {
    image = "docker.io/sissbruecker/linkding:1.44.1";
    # Caddy proxies in from localhost
    ports = [ "127.0.0.1:9091:9090" ];
    volumes = [ "/var/lib/linkding/data:/etc/linkding/data" ];
    environment = {
      LD_CSRF_TRUSTED_ORIGINS = "https://ld.rawliyosh.com";
      LD_ENABLE_AUTH_PROXY = "False";
      LD_AUTH_PROXY_LOGOUT_URL = "https://auth.rawliyosh.com/application/o/linkding/end-session/";
      LD_ENABLE_OIDC = "True";
      OIDC_USER_PKCE = "True";
      OIDC_VERIFY_SSL = "True";
      OIDC_OP_AUTHORIZATION_ENDPOINT = "https://auth.rawliyosh.com/application/o/authorize/";
      OIDC_OP_TOKEN_ENDPOINT = "https://auth.rawliyosh.com/application/o/token/";
      OIDC_OP_JWKS_ENDPOINT = "https://auth.rawliyosh.com/application/o/linkding/jwks/";
      OIDC_OP_USER_ENDPOINT = "https://auth.rawliyosh.com/application/o/userinfo/";
      OIDC_RP_SIGN_ALGO = "RS256";
      LD_DISABLE_URL_VALIDATION = "True";
    };
    environmentFiles = [ config.sops.secrets."linkding/env".path ];
  };

  # Container runs as www-data (uid 33)
  systemd.tmpfiles.rules = [ "d /var/lib/linkding/data 0755 33 33 -" ];
}
