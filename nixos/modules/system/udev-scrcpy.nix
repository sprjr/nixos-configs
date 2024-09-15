{ config, lib, pkgs, ...}:

let
  scrcpy-rules = pkgs.writeTextFile {
    name = "81-scrcpy-trigger.rules";
    text = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee7", ACTION=="add", RUN+="/home/patrick/Documents/Scripts/bash/personal/system/scrcpy-trigger.sh"
    '';
    destination = "/etc/udev/rules.d/81-scrcpy-trigger.rules";
  };
in {
  services.udev.packages = [ scrcpy-rules ];
}
