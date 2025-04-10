{ config, pkgs, ... }:

{
# sops = {
#   defaultSopsFile = ../../../sops-nix/sops.yaml;
#   defaultSopsFormat = "yaml";
#   age.keyFile = "/home/patrick/.config/sops/age/keys.txt";
#
#   secrets = {
#     "kubernetes-homelab-node-key".owner = "patrick";
#   };
# };

  services.k3s = {
    enable = true;
    role = "agent";
    token = { token = config.sops.secrets."kubernetes-homelab-node-key"; };
    serverAddr = "https://100.67.20.13:6443";
  };
}
