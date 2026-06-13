{ config, pkgs, lib, ... }:

# Tangled Knot server — ATProto-backed self-hosted git forge.
# Prerequisites before importing this module:
#   1. Add to flake.nix inputs:
#        tangled = {
#          url = "git+https://tangled.org/@tangled.org/core";
#          inputs.nixpkgs.follows = "nixpkgs";
#        };
#   2. Add to the host's modules list in flake.nix:
#        tangled.nixosModules.knot
#        ./nixos/modules/homelab/tangled-knot.nix
#   3. Set server.owner and server.hostname below.

{
  services.tangled.knot = {
    enable = true;

    server = {
      # Your ATProto DID — find it at https://tangled.org/settings (Profile section).
      owner = "did:plc:REPLACEME";

      # Public domain for this knot. Must match your DNS record and TLS cert.
      hostname = "knot.example.com";

      # Bind locally; nginx handles TLS and proxies to this port.
      listenAddr = "127.0.0.1:5555";
      internalListenAddr = "127.0.0.1:5444";

      # Requires Linux kernel >= 5.13 (Landlock LSM). Safe to enable on modern kernels.
      secureMode = true;
    };

    appviewEndpoint = "https://tangled.org";

    # Opens port 22 in the firewall for git+ssh operations.
    openFirewall = true;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    virtualHosts."knot.example.com" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:5555";
        proxyWebsockets = true;
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    # Replace with the address that should receive Let's Encrypt expiry notices.
    defaults.email = "admin@example.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
