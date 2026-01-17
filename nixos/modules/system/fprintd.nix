{ configs, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.fprintd
    pkgs.haskellPackages.libfuse3
    pkgs.imagemagick
  ];

  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
    };
  };
}
