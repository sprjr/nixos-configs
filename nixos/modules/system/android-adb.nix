{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    escapeShellArg
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.android-adb;

  commands =
    lib.flatten (
      lib.mapAttrsToList (
        ns: keys:
        lib.mapAttrsToList (k: v: "shell settings put ${ns} ${k} ${escapeShellArg (toString v)}") keys
      ) cfg.settings
    )
    ++ map (p: "shell pm disable-user --user 0 ${escapeShellArg p}") cfg.disabledPackages
    ++ map (p: "shell pm enable ${escapeShellArg p}") cfg.enabledPackages;

  applyScript = pkgs.writeShellScript "android-adb-apply" ''
    set -uo pipefail

    ADB=${escapeShellArg "${pkgs.android-tools}/bin/adb"}
    DEVICE=${escapeShellArg (if cfg.device == null then "" else cfg.device)}

    adb_cmd() {
      if [ -n "$DEVICE" ]; then
        "$ADB" -s "$DEVICE" "$@"
      else
        "$ADB" "$@"
      fi
    }

    state=$(adb_cmd get-state 2>/dev/null || true)
    if [ "$state" != "device" ]; then
      echo "android-adb: no authorized device (state: ''${state:-none})"
      exit 0
    fi

    failed=0

    ${lib.concatMapStrings (c: ''
      if ! adb_cmd ${c} >/dev/null 2>&1; then
        echo "android-adb: failed: ${c}" >&2
        failed=$((failed + 1))
      fi
    '') commands}

    ${cfg.extraCommands}

    if [ "$failed" -gt 0 ]; then
      echo "android-adb: $failed operation(s) failed" >&2
      exit 1
    fi

    echo "android-adb: applied"
  '';

  serviceName = "android-adb-apply";
in
{
  options.services.android-adb = {
    enable = mkEnableOption "declarative Android device management over ADB";

    user = mkOption {
      type = types.str;
      default = "patrick";
      description = "User that runs the ADB server and the apply service.";
    };

    device = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "adb serial or host:port. Null targets the single attached device.";
    };

    settings = mkOption {
      type = types.attrsOf (types.attrsOf (types.either types.str types.int));
      default = { };
      example = {
        global.window_animation_scale = "0.5";
        secure.install_non_market_apps = 1;
      };
      description = "Android settings to apply, nested namespace -> key -> value.";
    };

    disabledPackages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "com.example.bloat" ];
      description = "Packages to disable for user 0.";
    };

    enabledPackages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Packages to re-enable for user 0.";
    };

    extraCommands = mkOption {
      type = types.lines;
      default = "";
      description = "Shell appended to the apply script; use adb_cmd to reach the device.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.${serviceName} = {
      description = "Apply declarative Android settings over ADB";
      wants = [ "network.target" ];
      after = [ "network.target" ];
      path = [ pkgs.android-tools ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        RemainAfterExit = false;
        ExecStart = "${applyScript}";
      };
    };

    environment.systemPackages = [
      pkgs.android-tools
      applyScript
    ];

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4ee7", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}="${serviceName}.service"
    '';
  };
}
