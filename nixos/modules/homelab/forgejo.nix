{
  config,
  pkgs,
  lib,
  ...
}:

let
  domain = "git.rawliyosh.com";
  # Data on the unraid NFS mount (repos + LFS).
  stateDir = "/mnt/unraid/Gitea";
  # Local ext4: the NFS export rejects writes from the forgejo uid.
  customDir = "/var/lib/forgejo/custom";
  format = pkgs.formats.ini { };
in
{
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
  sops.secrets."forgejo/lfs-jwt-secret" = {
    owner = "forgejo";
    mode = "0400";
  };

  services.forgejo = {
    enable = true;
    stateDir = stateDir;
    customDir = customDir;
    repositoryRoot = "${stateDir}/repositories";

    database = {
      type = "postgres";
      name = "forgejo";
      user = "forgejo";
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
        # Tailscale-only (Caddy proxies in); 3002 as Grafana owns 3000.
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3002;
        # 2222; system openssh owns 22.
        SSH_PORT = 2222;
        DISABLE_SSH = false;
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      security = {
        INSTALL_LOCK = true;
      };
    };

    # Via systemd LoadCredential; no plaintext in the nix store.
    secrets = {
      security = {
        SECRET_KEY = lib.mkForce config.sops.secrets."forgejo/secret-key".path;
        INTERNAL_TOKEN = lib.mkForce config.sops.secrets."forgejo/internal-token".path;
      };
      oauth2 = {
        JWT_SECRET = lib.mkForce config.sops.secrets."forgejo/oauth2-jwt-secret".path;
      };
      server = {
        # lfs.enable=true defaults this to a file under stateDir that isn't created.
        LFS_JWT_SECRET = lib.mkForce config.sops.secrets."forgejo/lfs-jwt-secret".path;
      };
    };
  };

  # Reachable over tailscale only; the external Caddy host proxies public traffic in.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    3002
    2222
  ];

  # Fail to start rather than run against an unmounted store.
  systemd.services.forgejo.unitConfig.RequiresMountsFor = [ stateDir ];

  # Mirror nixpkgs' preStart, leaving app.ini writable for the JWT secret.
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
