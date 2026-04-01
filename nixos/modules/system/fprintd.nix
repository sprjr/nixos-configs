{ configs, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.open-fprintd
    pkgs.fprintd-tod
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

  security.pam.services = {
    login.fprintAuth = true;
    sudo.fprintAuth = true;
    polkit-1.fprintAuth = true;
    swaylock.fprintAuth = true; # remove if not using swaylock
  };
}
