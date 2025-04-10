{ config, pkgs, ... }:

{
  sops.secrets.kubernetes-homelab-node-key = { };
  sops.templates."../../../../sops-nix/sops.yaml" = {
    owner = "patrick";
    content = ''
      password = "${config.sops.placeholder.kubernetes-homelab-node-key}"
    '';
  };

  services.k3s = {
    enable = true;
    role = "agent";
    token = "${config.sops.placeholder.kubernetes-homelab-node-key}";
    serverAddr = "https://100.67.20.13:6443";
  };
}
