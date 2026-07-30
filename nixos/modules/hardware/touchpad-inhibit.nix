{ pkgs, ... }:

let
  toggleTouchpad = pkgs.writeShellScript "toggle-touchpad" ''
    state="$1"
    for dev in /sys/class/input/event*/; do
      if ${pkgs.systemd}/bin/udevadm info --query=property "$dev" 2>/dev/null \
           | grep -q '^ID_INPUT_TOUCHPAD=1$'; then
        printf '%s' "$state" > "''${dev}inhibited" 2>/dev/null || true
      fi
    done
  '';
in {
  services.udev.extraRules = ''
    ACTION=="add",    SUBSYSTEM=="input", ENV{ID_INPUT_MOUSE}=="1", ENV{ID_INPUT_TOUCHPAD}!="1", TAG+="systemd", ENV{SYSTEMD_WANTS}="touchpad-inhibit@1.service"
    ACTION=="remove", SUBSYSTEM=="input", ENV{ID_INPUT_MOUSE}=="1", ENV{ID_INPUT_TOUCHPAD}!="1", TAG+="systemd", ENV{SYSTEMD_WANTS}="touchpad-inhibit@0.service"
  '';

  systemd.services."touchpad-inhibit@" = {
    description = "Toggle touchpad inhibit (state %i)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${toggleTouchpad} %i";
    };
  };
}
