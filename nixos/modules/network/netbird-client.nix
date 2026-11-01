{ config, lib, ... }:

let
  cfg = config.homelab.netbird-client;
in
{
  options.homelab.netbird-client.setupKey = lib.mkOption {
    type = lib.types.str;
    default = "netbird/setup-key-workstations";
    description = "SOPS key path holding the reusable NetBird setup key.";
  };

  config = {
    sops.secrets."${cfg.setupKey}" = {
      sopsFile = ../../../sops-nix/relay.yaml;
    };

    services.netbird.clients.default = {
      port = 51820;
      interface = "netbird0";
      login.enable = true;
      login.setupKeyFile = config.sops.secrets."${cfg.setupKey}".path;
      login.systemdDependencies = [ "sops-install-secrets.service" ];
      config.ManagementURL = {
        Scheme = "https";
        Host = "nb.rawliyosh.com:443";
      };
    };

    systemd.services.netbird-default.restartTriggers = [
      config.environment.etc."netbird-default/config.d/50-nixos.json".source
    ];
  };
}
