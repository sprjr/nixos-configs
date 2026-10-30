{ config, ... }:

let
  nbDomain = "nb.rawliyosh.com";
  nbAdminDomain = "nb-admin.rawliyosh.com";
  authDomain = "auth.rawliyosh.com";
  dataDir = "/var/lib/netbird";

  authentik = ''
    reverse_proxy /outpost.goauthentik.io/* http://${authDomain}:9000
    forward_auth http://${authDomain}:9000 {
      uri /outpost.goauthentik.io/auth/caddy
      copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
    }
  '';
in
{
  sops.secrets."netbird/store-encryption-key" = { };
  sops.secrets."netbird/auth-secret" = { };
  sops.secrets."netbird/relay-auth-secret" = { };
  sops.secrets."netbird/dashboard-oidc-secret" = { };

  systemd.tmpfiles.rules = [ "d ${dataDir} 0750 root root -" ];

  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.netbird-server = {
    image = "netbirdio/netbird-server:latest";
    ports = [
      "127.0.0.1:8081:80"
      "3478:3478/udp"
    ];
    volumes = [
      "${dataDir}:/var/lib/netbird"
      "${config.sops.templates.\"netbird-config\".path}:/etc/netbird/config.yaml:ro"
    ];
    environment = {
      NB_LETSENCRYPT_DOMAIN = "none";
      NB_DISABLE_LETSENCRYPT = "true";
    };
    environmentFiles = [ config.sops.secrets."netbird/auth-secret".path ];
    extraOptions = [ "--cap-add=NET_BIND_SERVICE" ];
  };

  virtualisation.oci-containers.containers.netbird-dashboard = {
    image = "netbirdio/dashboard:latest";
    ports = [ "127.0.0.1:8080:80" ];
    environment = {
      NETBIRD_MGMT_API_ENDPOINT = "https://${nbDomain}";
      NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://${nbDomain}";
      AUTH_AUTHORITY = "https://${authDomain}/application/o/netbird/";
      AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
      AUTH_REDIRECT_URI = "/auth";
      AUTH_SILENT_REDIRECT_URI = "/silent-auth";
      NETBIRD_TOKEN_SOURCE = "idToken";
      USE_AUTH0 = "false";
      LETSENCRYPT_DOMAIN = "none";
    };
    environmentFiles = [ config.sops.secrets."netbird/dashboard-oidc-secret".path ];
  };

  sops.templates."netbird-config" = {
    mode = "0400";
    content = ''
      server:
        listenAddress: ":80"
        exposedAddress: "https://${nbDomain}:443"
        authSecret: ${config.sops.placeholder."netbird/relay-auth-secret"}
        dataDir: "${dataDir}"
        logLevel: info
        logFile: console
        disableAnonymousMetrics: true
        auth:
          issuer: "https://${authDomain}/application/o/netbird/"
          localAuthDisabled: false
          signKeyRefreshEnabled: true
          dashboardRedirectURIs:
            - "https://${nbAdminDomain}/auth"
            - "https://${nbAdminDomain}/silent-auth"
          cliRedirectURIs:
            - "http://localhost:53000/"
        store:
          engine: sqlite
          encryptionKey: ${config.sops.placeholder."netbird/store-encryption-key"}
        stunPorts:
          - 3478
    '';
  };

  services.caddy.virtualHosts = {
    "${nbDomain}".extraConfig = ''
      @grpc header Content-Type application/grpc*
      reverse_proxy @grpc h2c://127.0.0.1:8081

      @backend path /relay* /ws-proxy/* /api/* /oauth2/*
      reverse_proxy @backend 127.0.0.1:8081
    '';

    "${nbAdminDomain}".extraConfig = authentik + ''
      reverse_proxy 127.0.0.1:8080
    '';
  };

  networking.firewall.allowedTCPPorts = [ 443 ];
  networking.firewall.allowedUDPPorts = [ 3478 ];
}
