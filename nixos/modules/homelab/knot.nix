{ config, pkgs, lib, tangled, ... }:

{
  sops.secrets.knot-server-secret = {
    sopsFile = ../../../sops-nix/sops.yaml;
    key = "knot.server_secret";
    owner = "knot";
    mode = "0400";
  };

  sops.templates."knot-env" = {
    content = ''
      KNOT_SERVER_SECRET=${config.sops.placeholder.knot-server-secret}
    '';
    path = "/run/secrets/knot-env";
    owner = "knot";
  };

  services.tangled.knot = {
    enable = true;
    package = tangled.packages.${pkgs.system}.knot;

    appviewEndpoint = "https://tangled.org";
    gitUser = "git";
    openFirewall = true;
    stateDir = "/mnt/unraid/Gitea/knot";

    repo = {
      scanPath = "/mnt/unraid/Gitea/knot/repos";
      mainBranch = "main";
    };

    git = {
      userName  = "knot.rawliyosh.com";
      userEmail = "noreply@rawliyosh.com";
    };

    server = {
      hostname = "knot.rawliyosh.com";
      owner    = "did:plc:CHANGEME";

      listenAddr         = "127.0.0.1:5555";
      internalListenAddr = "127.0.0.1:5444";

      dbPath = "/mnt/unraid/Gitea/knot/knotserver.db";

      plcUrl            = "https://plc.directory";
      jetstreamEndpoint = "wss://jetstream1.us-west.bsky.network/subscribe";

      logDids       = true;
      dev           = false;
      maxResponseKB = 5120;
    };
  };

  systemd.services.knot.serviceConfig.EnvironmentFile =
    config.sops.templates."knot-env".path;

  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@rawliyosh.com";
    certs."knot.rawliyosh.com" = {
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets.cloudflare-api-token.path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings   = true;
    recommendedGzipSettings  = true;

    virtualHosts."knot.rawliyosh.com" = {
      useACMEHost = "knot.rawliyosh.com";
      forceSSL    = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:5555";
      };

      locations."/events" = {
        proxyPass = "http://127.0.0.1:5555";
        extraConfig = ''
          proxy_set_header Upgrade    websocket;
          proxy_set_header Connection Upgrade;
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
