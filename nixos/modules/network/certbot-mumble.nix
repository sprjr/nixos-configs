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

    registerName = "The Messiest, Wettest Mumble Server Around";
    registerHostname = "talk.rawlinson.xyz";
    registerPassword = "";  # Will be overridden

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
      # Ensure directory exists
      mkdir -p /var/lib/murmur

      # If config doesn't exist, let murmur create it first
      if [ ! -f /var/lib/murmur/murmur.ini ]; then
        # Create a minimal config that murmur will expand
        touch /var/lib/murmur/murmur.ini
      fi

      # Read password from sops
      REGISTER_PASSWORD=$(cat ${config.sops.secrets.mumble-register-password.path})

      # Update or add registerpassword in config
      if grep -q "^registerpassword=" /var/lib/murmur/murmur.ini; then
        ${pkgs.gnused}/bin/sed -i \
          "s|^registerpassword=.*|registerpassword=$REGISTER_PASSWORD|" \
          /var/lib/murmur/murmur.ini
      else
        echo "registerpassword=$REGISTER_PASSWORD" >> /var/lib/murmur/murmur.ini
      fi
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
