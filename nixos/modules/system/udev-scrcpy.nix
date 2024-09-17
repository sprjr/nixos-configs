{ config, lib, pkgs, ...}:

let
  scrcpy-trigger = pkgs.writeShellScript "scrcpy-trigger" ''
    export DISPLAY=:0
    ${pkgs.scrcpy}/bin/scrcpy
  '';
in
{
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee7", ACTION=="add", RUN+="${pkgs.systemd}/bin/systemctl start scrcpy-trigger.service"
    '';

  systemd.services.scrcpy-trigger = {
    path = [ "${pkgs.scrcpy}/bin/scrcpy" ];
    description = "scrcpy Service";
    serviceConfig = {
      ExecStart = scrcpy-trigger;
      User = "patrick";
    };
  };
}
