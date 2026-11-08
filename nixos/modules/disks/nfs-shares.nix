{ config, lib, ... }:

let
  cfg = config.homelab.nfs-shares;
  inherit (lib)
    all hasInfix hasPrefix length listToAttrs mkIf mkOption nameValuePair optional types unique;

  commonOptions = [
    "nofail"
    "retry=0"
    "noatime"
    "x-systemd.automount"
    "x-systemd.mount-timeout=15s"
    "x-systemd.after=tailscaled.service"
    "x-systemd.after=netbird-default.service"
  ] ++ optional (cfg.version != null) "nfsvers=${cfg.version}";

  policies = {
    read-mostly = [ "softerr" "timeo=10" "retrans=2" "actimeo=5" ];
    write-critical = [ "hard" "timeo=600" "retrans=2" "actimeo=1" ];
  };

  mountPoints = map (share: share.mountPoint) cfg.shares;
in
{
  options.homelab.nfs-shares = {
    version = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Pin nfsvers= for every share; null lets mount.nfs negotiate.";
    };

    shares = mkOption {
      default = [ ];
      type = types.listOf (types.submodule ({ config, ... }: {
        options = {
          share = mkOption {
            type = types.str;
            description = "Export name below dauntless:/mnt/user";
          };
          mountPoint = mkOption {
            type = types.str;
            default = "/mnt/unraid/${config.share}";
          };
          workloadClass = mkOption {
            type = types.enum [ "read-mostly" "write-critical" ];
            default = "write-critical";
          };
          extraOptions = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
        };
      }));
    };
  };

  config = mkIf (cfg.shares != [ ]) {
    assertions = [
      {
        assertion = all (s: s.share != "" && !(hasPrefix "/" s.share) && !(hasInfix ".." s.share)) cfg.shares;
        message = "homelab.nfs-shares.share must be relative and contain no '..'";
      }
      {
        assertion = all (s: hasPrefix "/" s.mountPoint) cfg.shares;
        message = "homelab.nfs-shares.mountPoint must be absolute";
      }
      {
        assertion = length mountPoints == length (unique mountPoints);
        message = "homelab.nfs-shares.mountPoint values must be unique";
      }
    ];

    boot.supportedFilesystems = [ "nfs" ];

    fileSystems = listToAttrs (map (share:
      nameValuePair share.mountPoint {
        device = "dauntless:/mnt/user/${share.share}";
        fsType = "nfs";
        options = unique (commonOptions ++ policies.${share.workloadClass} ++ share.extraOptions);
      }
    ) cfg.shares);
  };
}
