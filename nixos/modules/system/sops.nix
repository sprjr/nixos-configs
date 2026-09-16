{
  pkgs,
  inputs,
  config,
  ...
}:

{
  sops = {
    defaultSopsFile = ../../../sops-nix/sops.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/patrick/.config/sops/age/keys.txt";

    secrets."kubernetes/kubernetes-homelab-node-key" = { };
  };

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
          exit 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
      done
    '';
  };
}
