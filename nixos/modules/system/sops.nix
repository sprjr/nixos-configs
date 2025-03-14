{ pkgs, inputs, config, ... }:

{
  sops.defaultSopsFile = ../../../sops-nix/sops.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/patrick/.config/sops/age/key.txt";
}
