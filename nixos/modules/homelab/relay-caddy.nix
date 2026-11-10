{ config, lib, ... }:

let
  # VPN upstreams by bare hostname (NetBird DNS, MagicDNS fallback)
  shikisha = "shikisha";
  wopr = "wopr";
  macnnix = "macnnix";
  stargazer = "stargazer";

  authentik = ''
    reverse_proxy /outpost.goauthentik.io/* http://${shikisha}:9000
    forward_auth http://${shikisha}:9000 {
        uri /outpost.goauthentik.io/auth/caddy
        copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
    }
  '';

  proxy = upstream: {
    extraConfig = ''
      reverse_proxy ${upstream}
    '';
  };

  # Authentik forward auth as top-level directives
  proxyAuth = upstream: {
    extraConfig = authentik + ''
      reverse_proxy ${upstream}
    '';
  };

  # Authentik forward auth inside a route block
  proxyAuthRoute = upstream: {
    extraConfig = ''
      route {
      ${authentik}
      reverse_proxy ${upstream}
      }
    '';
  };

  # Authentik forward auth with rewritten forwarded host
  proxyAuthPort = host: port: {
    extraConfig = authentik + ''
      encode gzip
      reverse_proxy /* ${host}:${toString port} {
          header_up X-Forwarded-Host {host}:${toString port}
          header_up -Origin
          header_up -Referer
      }
    '';
  };

  # Subdomain labels resolved from caddy/subdomains env file at runtime
  hidden = {
    # wopr
    WOPR_23378.extraConfig = ''
      encode gzip zstd
      reverse_proxy ${wopr}:23378
    '';
    WOPR_15030 = proxy "${wopr}:15030";
    WOPR_2283 = proxy "${wopr}:2283";
    WOPR_38584 = proxy "${wopr}:38584";
    WOPR_32400 = proxy "${wopr}:32400";
    WOPR_7878 = proxyAuth "${wopr}:7878";
    WOPR_8989 = proxyAuth "${wopr}:8989";
    WOPR_15000 = proxyAuthPort wopr 15000;
    WOPR_5690 = proxy "${wopr}:5690";

    # shikisha
    SHIKISHA_9000.extraConfig = ''
      reverse_proxy http://${shikisha}:9000 {
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-Host {host}
      }
    '';
    SHIKISHA_443 = proxy "${shikisha}:443";
    SHIKISHA_30300 = proxy "${shikisha}:30300";
    SHIKISHA_3002 = proxy "http://${shikisha}:3002";
    SHIKISHA_25151 = proxy "${shikisha}:25151";
    SHIKISHA_38080 = proxyAuthRoute "${shikisha}:38080";
    SHIKISHA_3456 = proxy "${shikisha}:3456";
    SHIKISHA_2021 = proxy "${shikisha}:2021";
    SHIKISHA_31122 = proxy "http://${shikisha}:31122";
    SHIKISHA_28981 = proxy "${shikisha}:28981";
    SHIKISHA_8989 = proxy "${shikisha}:8989";
    SHIKISHA_6052 = proxy "http://${shikisha}:6052";
    SHIKISHA_3000 = proxy "${shikisha}:3000";

    # macnnix
    MACNNIX_9925 = proxyAuth "${macnnix}:9925";
    MACNNIX_8086 = proxy "${macnnix}:8086";
    MACNNIX_8080 = proxy "${macnnix}:8080";
    MACNNIX_11234 = proxyAuthPort macnnix 11234;
    MACNNIX_40001 = proxyAuthRoute "${macnnix}:40001";

    # local
    LOCAL_9091 = proxy "localhost:9091";
    LOCAL_3551 = proxyAuthRoute "localhost:3551";
  };
in
{
  sops.secrets."caddy/subdomains".restartUnits = [ "caddy.service" ];
  sops.secrets."cloudflare/acme-env" = { };

  # Wildcard cert via DNS-01 keeps per-service names out of CT logs
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@rawliyosh.com";
    certs."rawliyosh.com" = {
      domain = "*.rawliyosh.com";
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets."cloudflare/acme-env".path;
    };
  };

  services.caddy = {
    enable = true;
    environmentFile = config.sops.secrets."caddy/subdomains".path;

    virtualHosts =
      lib.mapAttrs' (
        id: v: lib.nameValuePair ("{$" + id + "}.rawliyosh.com") (v // { useACMEHost = "rawliyosh.com"; })
      ) hidden
      // {
        "plex.rawlinson.xyz" = proxy "http://${wopr}:32400";
        "pdf.rawlinson.xyz" = proxyAuthRoute "${macnnix}:38080";
      };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
