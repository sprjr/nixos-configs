{ pkgs, inputs, config, ... }:

{
  sops = {
    defaultSopsFile = ../../../sops-nix/sops.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/patrick/.config/sops/age/keys.txt";

    secrets."kubernetes/kubernetes-homelab-node-key" = { };
  };
}
