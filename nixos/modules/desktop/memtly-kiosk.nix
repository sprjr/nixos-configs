{ config, lib, pkgs, ... }:

let
  cfg = config.services.memtly-kiosk;

  # Keycodes from linux/input-event-codes.h; chord is Ctrl+Alt+End.
  chord = "29 56 107";

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

  supervisor = pkgs.writeScript "memtly-kiosk-supervisor" ("#!${pkgs.python3}/bin/python3\n" + ''
    import glob, os, select, struct, subprocess, sys, time

    CAGE = "${lib.getExe pkgs.cage}"
    BROWSER = "${browser}"
    CTRL, ALT, END = ${chord}
    EV_KEY, KEY_DOWN, KEY_UP = 1, 1, 0


    def open_devices():
        fds = {}
        for path in sorted(glob.glob("/dev/input/event*")):
            try:
                fds[os.open(path, os.O_RDONLY | os.O_NONBLOCK)] = path
            except OSError:
                continue
        return fds


    def main():
        child = subprocess.Popen([CAGE, "-s", "--", BROWSER])
        fds = open_devices()
        held = set()

        while child.poll() is None:
            if not fds:
                time.sleep(1)
                fds = open_devices()
            ready, _, _ = select.select(list(fds), [], [], 1.0)
            for fd in ready:
                try:
                    buf = os.read(fd, 24 * 64)
                except OSError:
                    os.close(fd)
                    del fds[fd]
                    continue
                for off in range(0, len(buf) - 23, 24):
                    _, _, kind, code, value = struct.unpack("llHHi", buf[off:off + 24])
                    if kind != EV_KEY:
                        continue
                    if value == KEY_DOWN:
                        held.add(code)
                    elif value == KEY_UP:
                        held.discard(code)

            if {CTRL, ALT, END} <= held:
                child.terminate()
                try:
                    child.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
                break

        return child.returncode or 0


    sys.exit(main())
  '');

  session = pkgs.writeShellScript "memtly-kiosk-session" ''
    for _ in $(seq 1 30); do
      ${lib.getExe pkgs.curl} -sf -o /dev/null --max-time 5 ${lib.escapeShellArgs [ cfg.url ]} && break
      sleep 2
    done
    exec ${supervisor}
  '';

  desktopFile = pkgs.writeText "memtly-kiosk.desktop" ''
    [Desktop Entry]
    Type=Application
    Name=Memtly Kiosk
    Exec=${session}
  '';

  # providedSessions is what services.displayManager.sessionPackages validates.
  sessionPackage = pkgs.runCommand "memtly-kiosk-session-package" { } ''
    install -Dm644 ${desktopFile} $out/share/wayland-sessions/memtly-kiosk.desktop
  '' // { providedSessions = [ "memtly-kiosk" ]; };
in
{
  options.services.memtly-kiosk = {
    enable = lib.mkEnableOption "a Memtly kiosk entry in the greetd session menu";

    url = lib.mkOption {
      type = lib.types.str;
      default = "http://stargazer:8080";
      description = "Page the kiosk displays.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "kiosk";
      description = "Account the kiosk session authenticates as.";
    };

    passwordSecret = lib.mkOption {
      type = lib.types.str;
      default = "cage-kiosk/stargazer-memtly";
      description = ''
        sops secret holding the kiosk account's password hash, made with
        `mkpasswd -m sha-512`. PAM cannot start the session without it.
      '';
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

    ignoreIdleAndLid = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Stop logind suspending the host while it presents. Host-wide, so it
        affects interactive sessions on the same machine too.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # neededForUsers decrypts this before activation writes /etc/shadow.
    sops.secrets.${cfg.passwordSecret} = {
      neededForUsers = true;
    };

    users.groups.${cfg.user} = { };
    users.users.${cfg.user} = {
      isNormalUser = true;
      group = cfg.user;
      hashedPasswordFile = config.sops.secrets.${cfg.passwordSecret}.path;
      extraGroups = [ "video" "render" "input" ];
    };

    # Memtly tracks the display as a guest by cookie, so this must outlive a relaunch.
    systemd.tmpfiles.rules = [
      "d ${cfg.profileDir} 0700 ${cfg.user} ${cfg.user} -"
    ];

    services.displayManager.sessionPackages = [ sessionPackage ];

    services.logind.settings.Login = lib.mkIf cfg.ignoreIdleAndLid {
      IdleAction = "ignore";
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };
  };
}
