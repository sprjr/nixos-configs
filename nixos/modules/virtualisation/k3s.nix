{ config, lib, ... }:

let
  cfg = config.homelab.k3s;
in
{
  options.homelab.k3s = {
    enable = lib.mkEnableOption "k3s cluster node";

    role = lib.mkOption {
      type = lib.types.enum [ "server" "agent" ];
      description = "k3s role for this node";
    };

    serverAddr = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Server URL for agent nodes";
    };

    tokenFile = lib.mkOption {
      type = lib.types.path;
      default = config.sops.secrets."kubernetes/kubernetes-homelab-node-key".path;
      description = "Path to the k3s join token file";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra flags passed to k3s";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 6443 ];
    networking.firewall.allowedUDPPorts = [ 4789 8472 ];

    services.k3s = {
      enable = true;
      inherit (cfg) role tokenFile extraFlags;
    } // lib.optionalAttrs (cfg.role == "agent") {
      serverAddr = cfg.serverAddr;
    };
  };
}
