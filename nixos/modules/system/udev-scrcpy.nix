{ config, lib, pkgs, ...}:

{
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee7", ACTION=="add", RUN+="${pkgs.writeShellScript "scrcpy-trigger" ''
        ${pkgs.scrcpy}/bin/scrcpy
    ''}"
  '';
}
