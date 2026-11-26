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
      # Binds the overlay resolver on :53, which hardening's capability set forbids
      hardened = false;
      login.enable = true;
      login.setupKeyFile = config.sops.secrets."${cfg.setupKey}".path;
      login.systemdDependencies = lib.optional (config.systemd.services ? sops-secrets-rendered) "sops-secrets-rendered.service";
      config.ManagementURL = {
        Scheme = "https";
        Host = "nb.rawliyosh.com:443";
      };
      # Keep port 22 on netbird0 for OpenSSH instead of NetBird's built-in server
      config.ServerSSHAllowed = false;
    };

    systemd.services.netbird-default.restartTriggers = [
      config.environment.etc."netbird-default/config.d/50-nixos.json".source
    ];

    systemd.services.netbird-default-login.wantedBy = [ "multi-user.target" ];

    # Tailscale's ts-input drops 100.64.0.0/10 sources arriving off netbird0
    networking.firewall.extraCommands = ''
      iptables -w -C INPUT -i netbird0 -j ACCEPT 2>/dev/null ||
        iptables -w -I INPUT -i netbird0 -j ACCEPT
    '';
  };
}
