{
  pkgs,
  inputs,
  config,
  ...
}:

let
  ageKeyFile = "/var/lib/sops-nix/key.txt";
in
{
  sops = {
    defaultSopsFile = ../../../sops-nix/sops.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = ageKeyFile;

    secrets."kubernetes/kubernetes-homelab-node-key" = { };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root -"
  ];

  # Fixing a sops race condition discovered on `badgey`
  systemd.services.sops-secrets-rendered = {
    description = "Wait for SOPS secrets to be available";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      elapsed=0
      while [ ! -d /run/secrets ] || [ -z "$(ls -A /run/secrets 2>/dev/null)" ]; do
        if [ "$elapsed" -ge 120 ]; then
          echo "SOPS secrets not available after 120 s" >&2
          if [ ! -f ${ageKeyFile} ]; then
            echo "No age key at ${ageKeyFile} — place it root-owned 0400 at deploy time" >&2
          fi
          exit 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
      done
    '';
  };
}
