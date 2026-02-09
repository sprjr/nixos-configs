{ config, pkgs, ... }:

{
  # ACME / Let's Encrypt
  security.acme = {
    acceptTerms = true;
    defaults.email = builtins.readFile config.sops.secrets.acme-email.path;

    certs."talk.rawlinson.xyz" = {
      group = "murmur";
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets.cloudflare-api-token.path;
      postRun = "systemctl reload murmur.service";
    };
  };

  # Murmur (Mumble Server)
  services.murmur = {
    enable = true;

    welcometext = "Welcome to the Jungle";
    bandwidth = 130000;
    users = 100;

    registerName = "The Messiest, Wettest Mumble Server";
    registerHostname = "talk.rawlinson.xyz";
    registerPassword = "";

    sslCert = "/var/lib/acme/talk.rawlinson.xyz/fullchain.pem";
    sslKey = "/var/lib/acme/talk.rawlinson.xyz/key.pem";

    extraConfig = ''
      allowhtml=true
      logfile=/var/log/murmur/murmur.log
      database=/var/lib/murmur/murmur.sqlite
    '';
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
  };

  # Ensure murmur can read certificates
  systemd.services.murmur = {
    serviceConfig = {
      SupplementaryGroups = [ "murmur" ];
    };
  };
}
