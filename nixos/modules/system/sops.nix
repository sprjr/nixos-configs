{ pkgs, inputs, config, ... }:

{
  imports = [ <sops-nix/modules/sops> ];

  sops.defaultSopsFile = ../../../sops-nix/sops.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/patrick/.config/sops/age/key.txt";
}
