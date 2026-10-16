{ ... }:

let
  # Tailnet upstreams by MagicDNS name
  shikisha = "shikisha";
  wopr = "wopr-0";
  macnnix = "macnnix";
  trixos = "trixos";
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
      tls acme@rawliyosh.com
      reverse_proxy /* ${host}:${toString port} {
          header_up X-Forwarded-Host {host}:${toString port}
          header_up -Origin
          header_up -Referer
      }
    '';
  };
in
{
  services.caddy = {
    enable = true;

    virtualHosts = {
      # wopr
      "audiobooks.rawliyosh.com".extraConfig = ''
        encode gzip zstd
        reverse_proxy ${wopr}:23378
      '';
      "gift.rawliyosh.com" = proxy "${wopr}:15030";
      "photos.rawliyosh.com" = proxy "${wopr}:2283";
      "share.rawliyosh.com" = proxy "${wopr}:38584";
      "plex.rawliyosh.com" = proxy "${wopr}:32400";
      "plex.rawlinson.xyz" = proxy "http://${wopr}:32400";
      "radarr.rawliyosh.com" = proxyAuth "${wopr}:7878";
      "sonarr.rawliyosh.com" = proxyAuth "${wopr}:8989";
      "books.rawliyosh.com" = proxyAuthPort wopr 15000;
      "wizarr.rawliyosh.com" = proxy "${wopr}:5690";

      # shikisha
      "auth.rawliyosh.com".extraConfig = ''
        reverse_proxy http://${shikisha}:9000 {
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Host {host}
        }
      '';
      "chat.rawliyosh.com" = proxy "${shikisha}:443";
      "gitea.rawliyosh.com" = proxy "${shikisha}:30300";
      "git.rawliyosh.com" = proxy "http://${shikisha}:3002";
      "snippets.rawliyosh.com" = proxy "${shikisha}:25151";
      "pdf.rawliyosh.com" = proxyAuthRoute "${shikisha}:38080";
      "vikunja.rawliyosh.com" = proxy "${shikisha}:3456";
      "loc.rawliyosh.com" = proxy "http://${shikisha}:31122";
      "esphome.rawliyosh.com" = proxy "http://${shikisha}:6052";
      "grafana.rawliyosh.com" = proxy "${shikisha}:3000";

      # macnnix
      "honoka.rawliyosh.com" = proxy "http://${macnnix}:28182";
      "mealie.rawliyosh.com" = proxyAuth "${macnnix}:9925";
      "remote.rawliyosh.com" = proxy "${macnnix}:8086";
      "search.rawliyosh.com" = proxy "${macnnix}:8080";
      "snipeit.rawliyosh.com" = proxyAuthPort macnnix 11234;
      "tools.rawliyosh.com" = proxyAuthRoute "${macnnix}:40001";
      "pdf.rawlinson.xyz" = proxyAuthRoute "${macnnix}:38080";

      # trixos
      "save.rawliyosh.com" = proxy "http://${trixos}:54545";
      "vault.rawliyosh.com" = proxyAuthRoute "http://${trixos}:36580";

      # stargazer
      "memtly.rawliyosh.com" = proxy "http://${stargazer}:8080";

      # local
      "ld.rawliyosh.com" = proxy "localhost:9091";
      "status.rawliyosh.com" = proxyAuthRoute "localhost:3551";

      # external
      "talk.rawlinson.xyz" = proxy "66.29.186.74";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
