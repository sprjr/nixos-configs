{ config, lib, pkgs, ... }:

let
  cfg = config.services.memtly-kiosk;

  browser = pkgs.writeShellScript "memtly-kiosk-browser" ''
    exec ${lib.getExe pkgs.chromium} \
      --kiosk \
      --ozone-platform=wayland \
      --user-data-dir=${cfg.profileDir} \
      --no-first-run \
      --no-default-browser-check \
      --disable-session-crashed-bubble \
      --disable-features=Translate \
      --password-store=basic \
      --autoplay-policy=no-user-gesture-required \
      ${lib.escapeShellArgs cfg.extraFlags} \
      ${lib.escapeShellArgs [ cfg.url ]}
  '';

  session = pkgs.writeShellScript "memtly-kiosk-session" ''
    until ${lib.getExe pkgs.curl} -sf -o /dev/null --max-time 5 ${lib.escapeShellArgs [ cfg.url ]}; do
      sleep 2
    done
    while true; do
      ${lib.getExe pkgs.cage} -- ${browser}
      sleep 3
    done
  '';
in
{
  options.services.memtly-kiosk = {
    enable = lib.mkEnableOption "Memtly as a greetd autologin kiosk";

    url = lib.mkOption {
      type = lib.types.str;
      default = "http://stargazer:8080";
      description = "Page the kiosk displays.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "kiosk";
      description = "Unprivileged account the kiosk session runs as.";
    };

    profileDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/memtly-kiosk/profile";
      description = "Chromium profile directory, persisted across launches.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional Chromium command-line flags.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.user} = { };
    users.users.${cfg.user} = {
      isNormalUser = true;
      group = cfg.user;
      hashedPassword = "!";
      extraGroups = [ "video" "render" ];
    };

    # Memtly tracks the display as a guest by cookie, so this must outlive a relaunch.
    systemd.tmpfiles.rules = [
      "d ${cfg.profileDir} 0700 ${cfg.user} ${cfg.user} -"
    ];

    services.greetd.settings.initial_session = {
      command = "${session}";
      user = cfg.user;
    };

    services.logind.settings.Login = {
      IdleAction = "ignore";
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };
  };
}
