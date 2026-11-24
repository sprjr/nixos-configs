{ config, pkgs, lib, ... }:

let
  cfg = config.homelab.garage;
in
{
  options.homelab.garage = {
    enable = lib.mkEnableOption "Garage S3-compatible object store";

    nodeName = lib.mkOption {
      type = lib.types.str;
      description = "Unique node name in the Garage cluster";
    };

    netbirdIP = lib.mkOption {
      type = lib.types.str;
      description = "NetBird IP to bind RPC and S3 API";
    };

    rpcPublicAddr = lib.mkOption {
      type = lib.types.str;
      description = "Public RPC address advertised to other nodes";
    };

    replicationFactor = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Garage replication factor";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/garage/data";
      description = "Directory for object data";
    };

    bootstrapPeers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of bootstrap peer RPC URLs";
    };
  };

  config = lib.mkIf cfg.enable {
    # Garage 1.3.1 is EOL in nixpkgs; permitted for the learning cluster only.
    nixpkgs.config.permittedInsecurePackages = [ "garage-${pkgs.garage.version}" ];

    sops.secrets = {
      garage_rpc_secret = {
        key = "garage/rpc_secret";
        owner = "garage";
      };
      garage_admin_token = {
        key = "garage/admin_token";
        owner = "garage";
      };
      garage_metrics_token = {
        key = "garage/metrics_token";
        owner = "garage";
      };
    };

    users.users.garage = {
      isSystemUser = true;
      group = "garage";
      home = "/var/lib/garage";
    };

    users.groups.garage = { };

    services.garage = {
      enable = true;
      package = pkgs.garage;
      logLevel = "debug";
      settings = {
        metadata_dir = "/var/lib/garage/meta";
        node_name = cfg.nodeName;
        data_dir = cfg.dataDir;
        replication_factor = cfg.replicationFactor;
        bootstrap_peers = cfg.bootstrapPeers;

        rpc_bind_addr = "${cfg.netbirdIP}:3901";
        rpc_public_addr = cfg.rpcPublicAddr;
        rpc_secret = config.sops.secrets.garage_rpc_secret.path;

        db_engine = "sqlite";

        s3_api = {
          api_bind_addr = "${cfg.netbirdIP}:3900";
          root_domain = ".s3.garage.localhost";
          s3_region = "garage";
        };

        s3_web = {
          bind_addr = "[::]:3902";
          index = "index.html";
          root_domain = ".web.garage.localhost";
        };

        k2v_api = {
          api_bind_addr = "[::]:3904";
        };

        admin = {
          api_bind_addr = "[::]:3903";
          admin_token = config.sops.secrets.garage_admin_token.path;
          metrics_token = config.sops.secrets.garage_metrics_token.path;
        };
      };
    };

    networking.firewall.interfaces.netbird0.allowedTCPPorts = [ 3900 3901 ];
  };
}
