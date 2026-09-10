{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Public hostname for the Forgejo instance. Change to taste; ROOT_URL below
  # follows this value. Public traffic is proxied in by the external Caddy host.
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
        # Bind on all interfaces so the external Caddy host (which proxies via
        # tailscale) can reach it. Firewall restricts this to tailscale0.
        HTTP_ADDR = "0.0.0.0";
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

  # ---- Firewall ----
  # Forgejo HTTP + SSH reachable over tailscale only. The external Caddy host
  # proxies public traffic in via tailscale (no nginx on this host).
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    3000
    2222
  ];
}
