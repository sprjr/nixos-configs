{ config, pkgs, lib, ... }:

{
  # Nix-sops configuration
  sops.secrets = {
    garage_rpc_secret = {
      sopsFile = ../../../../sops-nix/sops.yaml;
      key = "garage.rpc_secret";
      owner = "garage";
    };
    garage_admin_token = {
      sopsFile = ../../../../sops-nix/sops.yaml;
      key = "garage.admin_token";
      owner = "garage";
    };
    garage_metrics_token = {
      sopsFile = ../../../../sops-nix/sops.yaml;
      key = "garage.metrics_token";
      owner = "garage";
    };
  };

  services.garage = {
    enable = true;
    package = pkgs.garage;
    environmentFile = /etc/garage.toml;
    logLevel = "debug";
    settings = {
      metadata_dir = "/var/lib/garage/meta";
      data_dir = "/var/lib/garage/data";

      rpc_bind_addr = "[::]:3901";
      rpc_public_addr = "http://100.67.20.13:3901";
      rpc_secret = config.sops.secrets.garage_rpc_secret.path;

      # node identity (must be unique per node)
      node_name = "shikisha";

      db_engine = "sqlite";
      replication_factor = 1;

      # cluster bootstrap
      #bootstrap_peers = []; # list other nodes' RPC URLs

      # Optional: S3 interface
      s3_api = {
        api_bind_addr = "[::]:3900";
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

  users.users.garage = {
    isSystemUser = true;
    group = "garage";
    home = "/var/lib/garage";
  };

  users.groups.garage = {};

  # open firewall ports
  networking.firewall.allowedTCPPorts = [ 3900 3901 ];
}
