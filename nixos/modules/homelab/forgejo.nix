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
  # The writable config/secret dir is kept OFF the NFS mount. When useWizard is
  # disabled the module writes app.ini and the secret files under customDir, and
  # the unraid NFS export does not permit the forgejo uid to write there (open
  # .../app.ini: permission denied). A local dir keeps those writes on ext4 while
  # repositories/LFS data stay on NFS stateDir.
  customDir = "/var/lib/forgejo/custom";
  # INI formatter for the generated app.ini (same as the nixpkgs forgejo module).
  format = pkgs.formats.ini { };
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
  # LFS JWT secret: lfs.enable=true adds a 5th LoadCredential whose default
  # source path is under the NFS stateDir (${stateDir}/custom/conf/lfs_jwt_secret).
  # That file is never auto-generated on a fresh stateDir, so the unit dies at
  # the systemd CREDENTIALS step. Override with a sops-managed path via
  # services.forgejo.secrets.server.LFS_JWT_SECRET below.
  sops.secrets."forgejo/lfs-jwt-secret" = {
    owner = "forgejo";
    mode = "0400";
  };

  # ---- Forgejo service (nixpkgs module) ----
  services.forgejo = {
    enable = true;
    stateDir = stateDir;
    # customDir is kept off the NFS mount (see let binding above): the module
    # writes app.ini + secret files here when useWizard/INSTALL_LOCK is set.
    customDir = customDir;
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
        # Port 3002: 3000 is taken by Grafana on shikisha.
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3002;
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
    # mkForce: the nixpkgs module sets these to paths under stateDir by default;
    # we override with sops-managed paths.
    secrets = {
      security = {
        SECRET_KEY = lib.mkForce config.sops.secrets."forgejo/secret-key".path;
        INTERNAL_TOKEN = lib.mkForce config.sops.secrets."forgejo/internal-token".path;
      };
      oauth2 = {
        JWT_SECRET = lib.mkForce config.sops.secrets."forgejo/oauth2-jwt-secret".path;
      };
      # LFS JWT secret — added automatically by lfs.enable=true; mkForce it to the
      # sops path so it doesn't point at the never-generated NFS default.
      server = {
        LFS_JWT_SECRET = lib.mkForce config.sops.secrets."forgejo/lfs-jwt-secret".path;
      };
    };
  };

  # ---- Firewall ----
  # Forgejo HTTP + SSH reachable over tailscale only. The external Caddy host
  # proxies public traffic in via tailscale (no nginx on this host).
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    3002
    2222
  ];

  # ---- Startup fix: keep app.ini writable so Forgejo can persist oauth2 JWT ----
  # Root cause (matches NixOS/nixpkgs#262802 + Forgejo FIXME forgejo@193ac67176):
  # Forgejo ALWAYS persists an oauth2 JWT secret back into app.ini during
  # `forgejo migrate` at startup, even when one is already set (and regardless
  # of oauth2 ENABLE). The nixpkgs module's preStart does `chmod u-w app.ini`
  # after generating it, so that persist hits EACCES:
  #   error saving JWT Secret for custom config ... permission denied
  # Sops secrets (kept per the locked decision) are injected correctly via
  # LoadCredential/env; the failure is purely the read-only file. We therefore
  # override the module's preStart wholesale (mkForce) to mirror the module
  # EXACTLY (cp generated app.ini, chmod u+w, environment-to-ini, then
  # `forgejo migrate` + hook/keys regenerate) WITHOUT the trailing chmod u-w.
  # Mirroring, not appending: because the module's `migrate` runs inside the
  # same preStart AFTER the u-w, an `mkAfter` would be too late. We drop the
  # hardening so Forgejo's own persist works. (No secrets in the store: values
  # still arrive via LoadCredential as FORGEJO__<SECTION>__<KEY>__FILE.)
  systemd.services.forgejo.preStart = lib.mkForce ''
    (umask 027
      config='${customDir}/conf/app.ini'
      cp -f '${format.generate "app.ini" config.services.forgejo.settings}' "$config"
      chmod u+w "$config"
      ${lib.getExe' config.services.forgejo.package "environment-to-ini"} --config "$config"
    )
    ${lib.getExe config.services.forgejo.package} migrate
    ${lib.getExe config.services.forgejo.package} admin regenerate hooks
    if [ -r ${stateDir}/.ssh/authorized_keys ]
    then
      ${lib.getExe config.services.forgejo.package} admin regenerate keys
    fi
  '';
}
