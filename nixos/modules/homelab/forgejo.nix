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

  # Wait for the store mount before migrate; nixpkgs runs preStart ahead of ExecStartPre.
  systemd.services.forgejo = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig.TimeoutStartSec = 300;
  };

  # Mirror nixpkgs' preStart, leaving app.ini writable for the JWT secret.
  systemd.services.forgejo.preStart = lib.mkForce ''
    # preStart runs before ExecStartPre, so wait here or migrate runs against an unmounted store.
    for _ in $(${pkgs.coreutils}/bin/seq 1 24); do
      if ${pkgs.util-linux}/bin/findmnt -rno FSTYPE --target ${stateDir} | ${pkgs.gnugrep}/bin/grep -qE '^nfs4?$'; then
        break
      fi
      ${pkgs.coreutils}/bin/ls ${stateDir} >/dev/null 2>&1 || true
      ${pkgs.coreutils}/bin/sleep 5
    done
    if ! ${pkgs.util-linux}/bin/findmnt -rno FSTYPE --target ${stateDir} | ${pkgs.gnugrep}/bin/grep -qE '^nfs4?$'; then
      echo "${stateDir} is not an nfs mount after 120s" >&2
      exit 1
    fi

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
