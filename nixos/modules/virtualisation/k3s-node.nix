{ config, pkgs, ... }:

{
  services.k3s = {
    enable = true;
    role = "agent";
    token = { token = config.sops.secrets."kubernetes-homelab-node-key"; };
    serverAddr = "https://100.67.20.13:6443";
  };
}
