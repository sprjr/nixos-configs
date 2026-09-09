{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Public hostname for the Forgejo instance. Change to taste; the nginx
  # vhost and ROOT_URL below follow this value.
  domain = "git.rawliyosh.com";
  # Data lives on the existing unraid NFS mount (see modules/disks/unraid-gitea.nix).
  stateDir = "/mnt/unraid/Gitea";
in
{
  # ---- Secrets (sops-nix) ----
  # All values are user-created sops entries; the agent never supplies them.
  # See the PR body for the exact `sops set` commands.
  sops.secrets."forgejo/database-password" = {
    owner = "forgejo";
    mode = "0400";
  };
  sops.secrets."forgejo/secret-key" = {
    owner = "forgejo";
    mode = "0400";
  };
  sops.secrets."forgejo/internal-token" = {
    owner = "forgejo";
    mode = "0400";
  };
  sops.secrets."forgejo/oauth2-jwt-secret" = {
    owner = "forgejo";
    mode = "0400";
  };

  # ---- Forgejo service (nixpkgs module) ----
  services.forgejo = {
    enable = true;
    stateDir = stateDir;
    repositoryRoot = "${stateDir}/repositories";

    database = {
      type = "postgres";
      name = "forgejo";
      user = "forgejo";
      # createDatabase = true auto-provisions a local postgres with the
      # forgejo user/db; the password is read from the sops secret file.
      passwordFile = config.sops.secrets."forgejo/database-password".path;
    };

    lfs.enable = true;

    settings = {
      DEFAULT = {
        APP_NAME = "Forgejo";
        RUN_MODE = "prod";
      };
      server = {
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        # Forgejo's own SSH on a non-conflicting port (system openssh owns 22).
        SSH_PORT = 2222;
        DISABLE_SSH = false;
      };
      service = {
        # Personal instance: no open registration.
        DISABLE_REGISTRATION = true;
      };
      security = {
        # Manage everything declaratively; no web install wizard.
        INSTALL_LOCK = true;
      };
    };

    # Sensitive values are injected via systemd LoadCredential as
    # FORGEJO__<SECTION>__<KEY>__FILE env vars (no plaintext in the nix store).
    secrets = {
      security = {
        SECRET_KEY = config.sops.secrets."forgejo/secret-key".path;
        INTERNAL_TOKEN = config.sops.secrets."forgejo/internal-token".path;
      };
      oauth2 = {
        JWT_SECRET = config.sops.secrets."forgejo/oauth2-jwt-secret".path;
      };
    };
  };

  # ---- Reverse proxy (nginx) ----
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@rawliyosh.com";
  };

  # ---- Firewall ----
  # Public web via nginx (80/443). Forgejo HTTP + SSH reachable over tailscale.
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    3000
    2222
  ];
}
