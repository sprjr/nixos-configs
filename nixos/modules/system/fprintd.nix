{ configs, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.open-fprintd
    pkgs.fprintd-clients
    pkgs.haskellPackages.libfuse3
    pkgs.imagemagick
    pkgs.python3-validity
  ];

  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
    };
  };
}
