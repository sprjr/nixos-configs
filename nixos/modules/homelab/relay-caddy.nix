{ ... }:

let
  # Tailnet upstreams by MagicDNS name
  shikisha = "shikisha";
  wopr = "wopr";
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
      "paperless.rawliyosh.com" = proxy "${shikisha}:28981";
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

      # static
      "test.rawliyosh.com".extraConfig = ''
        encode gzip zstd
        root * /etc/test-site
        file_server
      '';

      # external
      "talk.rawlinson.xyz" = proxy "66.29.186.74";
    };
  };

  environment.etc."test-site/index.html".text = ''
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Hi dad</title>
    <style>
      :root { color-scheme: dark; }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        place-items: center;
        font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
        background: radial-gradient(circle at 30% 15%, #1e40af 0%, #0f172a 55%, #020617 100%);
        color: #e0f2fe;
      }
      main {
        text-align: center;
        padding: 3rem 4rem;
        border-radius: 20px;
        background: rgba(15, 42, 90, 0.55);
        border: 1px solid rgba(125, 211, 252, 0.35);
        box-shadow: 0 24px 60px -20px rgba(2, 6, 23, 0.9);
        backdrop-filter: blur(6px);
      }
      h1 {
        margin: 0;
        font-size: clamp(2.5rem, 8vw, 5rem);
        letter-spacing: -0.02em;
        background: linear-gradient(180deg, #ffffff, #7dd3fc);
        -webkit-background-clip: text;
        background-clip: text;
        color: transparent;
      }
      p {
        margin: 1rem 0 0;
        color: #93c5fd;
        font-size: 0.9rem;
        letter-spacing: 0.12em;
        text-transform: uppercase;
      }
    </style>
    </head>
    <body>
    <main>
    <h1>Hi dad</h1>
    <p>test.rawliyosh.com</p>
    </main>
    </body>
    </html>
  '';

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
