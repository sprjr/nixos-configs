{ config, lib, ... }:

let
  cfg = config.homelab.netbird;
  domain = "nb.rawliyosh.com";
  dataDir = "/var/lib/netbird";
in
{
  options.homelab.netbird.adminEmail = lib.mkOption {
    type = lib.types.str;
    default = "admin@rawliyosh.com";
    description = "Initial local admin account for the embedded IdP.";
  };

  config = {
    sops.secrets."netbird/server-auth-secret" = { };
    sops.secrets."netbird/store-encryption-key" = { };
    sops.secrets."netbird/admin-password" = { };

    systemd.tmpfiles.rules = [ "d ${dataDir} 0700 root root -" ];

    virtualisation.oci-containers.containers = {
      netbird-server = {
        image = "docker.io/netbirdio/netbird-server:0.82.0";
        cmd = [ "--config" "/etc/netbird/config.yaml" ];
        # Caddy proxies in from localhost; STUN must be reachable directly
        ports = [
          "127.0.0.1:8081:80"
          "3478:3478/udp"
        ];
        volumes = [
          "${dataDir}:/var/lib/netbird"
          "${config.sops.templates."netbird-config".path}:/etc/netbird/config.yaml:ro"
        ];
      };

      netbird-dashboard = {
        image = "docker.io/netbirdio/dashboard:v2.26.0";
        ports = [ "127.0.0.1:8080:80" ];
        environment = {
          NETBIRD_MGMT_API_ENDPOINT = "https://${domain}";
          NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://${domain}";
          AUTH_AUTHORITY = "https://${domain}/oauth2";
          AUTH_CLIENT_ID = "netbird-dashboard";
          AUTH_AUDIENCE = "netbird-dashboard";
          AUTH_CLIENT_SECRET = "";
          AUTH_SUPPORTED_SCOPES = "openid profile email groups";
          AUTH_REDIRECT_URI = "/nb-auth";
          AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
          USE_AUTH0 = "false";
          LETSENCRYPT_DOMAIN = "none";
        };
      };
    };

    sops.templates."netbird-config" = {
      mode = "0400";
      content = ''
        server:
          listenAddress: ":80"
          exposedAddress: "https://${domain}:443"
          authSecret: "${config.sops.placeholder."netbird/server-auth-secret"}"
          dataDir: "${dataDir}"
          logLevel: info
          logFile: console
          disableAnonymousMetrics: true
          stunPorts:
            - 3478
          auth:
            issuer: "https://${domain}/oauth2"
            localAuthDisabled: false
            dashboardRedirectURIs:
              - "https://${domain}/nb-auth"
              - "https://${domain}/nb-silent-auth"
            cliRedirectURIs:
              - "http://localhost:53000/"
            owner:
              email: "${cfg.adminEmail}"
              password: "${config.sops.placeholder."netbird/admin-password"}"
          store:
            engine: sqlite
            encryptionKey: "${config.sops.placeholder."netbird/store-encryption-key"}"
      '';
    };

    services.caddy.virtualHosts."${domain}".extraConfig = ''
      @grpc path /signalexchange.SignalExchange/* /management.ManagementService/* /management.ProxyService/*
      handle @grpc {
        reverse_proxy h2c://127.0.0.1:8081
      }

      @server path /relay* /ws-proxy/* /api/* /oauth2/*
      handle @server {
        reverse_proxy 127.0.0.1:8081
      }

      handle {
        reverse_proxy 127.0.0.1:8080
      }
    '';

    networking.firewall.allowedUDPPorts = [ 3478 ];
  };
}
