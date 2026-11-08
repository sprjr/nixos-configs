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
    tokenFile = /opt/secrets/kubernetes/k3s-node.txt;
    serverAddr = "https://100.67.20.13:6443";
  };
}
