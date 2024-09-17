{ config, lib, pkgs, ...}:

let
  scrcpy-trigger = pkgs.writeShellScript "scrcpy-trigger" ''
    ${pkgs.scrcpy}/bin/scrcpy
  '';
in
{
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee7", TAG+="systemd", ENV{SYSTEMD_WANTS}="scrcpy-trigger.service", ACTION=="add", RUN+="${pkgs.systemd}/bin/systemctl start scrcpy-trigger.service"
    '';

  systemd.services.scrcpy-trigger = {
    path = [ "${pkgs.scrcpy}/bin/scrcpy" ];
    description = "scrcpy Service";
    environment = {
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
    serviceConfig = {
      ExecStart = scrcpy-trigger;
      User = "patrick";
    };
  };
}
