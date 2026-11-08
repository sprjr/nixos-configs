{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.tangled.knot = {
    enable = true;

    server = {
      owner = "did:plc:REPLACEME";
      hostname = "knot.example.com";
      listenAddr = "127.0.0.1:5555";
      internalListenAddr = "127.0.0.1:5444";
      secureMode = true;
    };
    appviewEndpoint = "https://tangled.org";
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
    defaults.email = "admin@example.com";
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
