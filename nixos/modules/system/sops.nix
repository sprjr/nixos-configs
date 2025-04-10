{ pkgs, inputs, config, ... }:

{
  imports =
    [
      inputs.sops-nix.nixosModules.sops
    ];

  sops.defaultSopsFile = ../../../sops-nix/sops.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/patrick/.config/sops/age/key.txt";

  sops.secrets.kubernetes-homelab-node-key = { };
}
