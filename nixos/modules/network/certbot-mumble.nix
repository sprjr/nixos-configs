{ config, pkgs, ... }:

{
  # Sops secrets
  sops.secrets = {
    cloudflare-api-token = {
      owner = "root";
      mode = "0400";
    };
    mumble-register-password = {
      owner = "murmur";
      mode = "0400";
    };
  };

  # ACME / Let's Encrypt
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@rawliyosh.com";

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
    registerPassword = "";  # Will be overridden by secret

    sslCert = "/var/lib/acme/talk.rawlinson.xyz/fullchain.pem";
    sslKey = "/var/lib/acme/talk.rawlinson.xyz/key.pem";

    extraConfig = ''
      allowhtml=true
      logfile=/var/log/murmur/murmur.log
      database=/var/lib/murmur/murmur.sqlite
    '';
  };

  # Inject register password from sops at runtime
  systemd.services.murmur = {
    preStart = ''
      # Read password from sops
      REGISTER_PASSWORD=$(cat ${config.sops.secrets.mumble-register-password.path})

      # Update config file with actual password
      ${pkgs.gnused}/bin/sed -i \
        "s|^registerpassword=.*|registerpassword=$REGISTER_PASSWORD|" \
        /var/lib/murmur/murmur.ini
    '';

    serviceConfig = {
      SupplementaryGroups = [ "murmur" ];
    };
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
  };
}
