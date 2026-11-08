{ ... }:

{
  sops = {
    defaultSopsFile = ../../sops-nix/sops.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/Users/patrick/.config/sops/age/keys.txt";
  };
}
