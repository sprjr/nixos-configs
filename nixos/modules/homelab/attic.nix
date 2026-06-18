{ config, pkgs, ... }:

{
  sops.secrets."atticd/env-file" = {
    owner = "atticd";
    restartUnits = [ "atticd.service" ];
  };
  sops.secrets."atticd/signing-key" = {
    owner = "atticd";
    restartUnits = [ "atticd.service" ];
  };
  # SSH deploy key with write access to sprjr/nixos-configs.
  # Add to SOPS with: sops sops-nix/sops.yaml
  # Generate with: ssh-keygen -t ed25519 -f /tmp/nixpkgs-cooldown-deploy -N ""
  # Add /tmp/nixpkgs-cooldown-deploy.pub as a deploy key (write) on the GitHub repo.
  sops.secrets."github/nixpkgs-cooldown-deploy-key" = {
    owner = "root";
    mode = "0400";
  };

  # Allow all Tailscale peers to reach the cache without a port-level rule.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets."atticd/env-file".path;
    settings = {
      listen = "[::]:8089";
      jwt = { };
      signing-key-path = config.sops.secrets."atticd/signing-key".path;
      # Warning: changing chunking values breaks deduplication for existing NARs.
      chunking = {
        nar-size-threshold = 64 * 1024;
        min-size = 16 * 1024;
        avg-size = 64 * 1024;
        max-size = 256 * 1024;
      };
    };
  };

  # Runs weekly and pins nixpkgs in flake.lock to the nixpkgs-unstable HEAD
  # from 7 days prior, then pushes to main so comin propagates it to all hosts.
  # Fires Sunday 00:00 Mountain Time (06:00 UTC) to land outside business hours.
  systemd.timers."nixpkgs-cooldown" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 06:00:00 UTC";
      Persistent = "true";
      Unit = "nixpkgs-cooldown.service";
    };
  };

  systemd.services."nixpkgs-cooldown" =
    let
      deployKey = config.sops.secrets."github/nixpkgs-cooldown-deploy-key".path;
    in
    {
      path = with pkgs; [
        curl
        git
        jq
        nix
        openssh
      ];
      environment = {
        HOME = "/var/lib/nixpkgs-cooldown";
        NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      };
      script = ''
        set -euo pipefail

        DEPLOY_KEY="${deployKey}"
        REPO_URL="git@github.com:sprjr/nixos-configs.git"
        REPO_DIR="/var/lib/nixpkgs-cooldown/repo"

        export GIT_SSH_COMMAND="ssh -i $DEPLOY_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

        UNTIL=$(date -d '7 days ago' --iso-8601=seconds)
        COMMIT=$(curl -sf \
          "https://api.github.com/repos/NixOS/nixpkgs/commits?sha=nixpkgs-unstable&until=$UNTIL&per_page=1" \
          | jq -r '.[0].sha')

        if [ -z "$COMMIT" ] || [ "$COMMIT" = "null" ]; then
          echo "ERROR: failed to resolve nixpkgs-unstable commit from 7 days ago" >&2
          exit 1
        fi

        echo "Target nixpkgs commit (7-day lag): $COMMIT"

        if [ -d "$REPO_DIR/.git" ]; then
          git -C "$REPO_DIR" fetch origin main
          git -C "$REPO_DIR" reset --hard origin/main
        else
          git clone "$REPO_URL" "$REPO_DIR"
        fi

        cd "$REPO_DIR"

        CURRENT=$(jq -r '.nodes.nixpkgs.locked.rev // empty' flake.lock 2>/dev/null || echo "")
        if [ "$CURRENT" = "$COMMIT" ]; then
          echo "nixpkgs already pinned to $COMMIT, no update needed"
          exit 0
        fi

        nix flake lock --override-input nixpkgs "github:NixOS/nixpkgs/$COMMIT"

        git config user.email "nixpkgs-cooldown@shikisha"
        git config user.name "nixpkgs-cooldown"
        git add flake.lock
        git commit -m "chore(nixpkgs): lag to $(date -d '7 days ago' '+%Y-%m-%d') [''${COMMIT:0:8}]"
        git push origin main
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        StateDirectory = "nixpkgs-cooldown";
      };
    };
}
