{ pkgs, ... }:

{
  home.packages = [ pkgs.nuclei ];

  # Ad hoc runs skip update checks; the scheduled job owns template updates and calls the binary by store path.
  # Not set in config.yaml: the scheduled job reads it too, and -duc disables -ut.
  home.shellAliases.nuclei = "nuclei -duc";

  # Static imports: gating on pkgs here queries config and recurses under NixOS-embedded home-manager.
  imports = [
    ./nuclei-systemd.nix
    ./nuclei-launchd.nix
  ];
}
