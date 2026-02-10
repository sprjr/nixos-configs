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
    mumble-server-password = {
      owner = "murmur";
      mode = "0400";
    };
    mumble-superuser-password = {
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
      postRun = "systemctl restart murmur.service";
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
    registerPassword = "";  # Will be injected
    password = "";  # Server password - will be injected

    sslCert = "/var/lib/acme/talk.rawlinson.xyz/fullchain.pem";
    sslKey = "/var/lib/acme/talk.rawlinson.xyz/key.pem";

    extraConfig = ''
      allowhtml=true
      database=/var/lib/murmur/murmur.sqlite

      # Disable remote admin interfaces for security
      ice=""
      dbus=system

      # Additional security settings
      allowping=false
      sendversion=false
    '';
  };

  # Override to inject passwords from sops
  systemd.services.murmur = {
    serviceConfig = {
      SupplementaryGroups = [ "murmur" ];
      LogsDirectory = "murmur";
      ReadWritePaths = [ "/var/log/murmur" ];
    };

    script = pkgs.lib.mkForce ''
      # Read passwords from sops
      REGISTER_PASSWORD=$(cat ${config.sops.secrets.mumble-register-password.path})
      SERVER_PASSWORD=$(cat ${config.sops.secrets.mumble-server-password.path})
      SUPERUSER_PASSWORD=$(cat ${config.sops.secrets.mumble-superuser-password.path})

      # Get the config file path
      CONFIG_FILE=/var/lib/murmur/murmur.ini

      # Update or add registerpassword
      if grep -q "^registerpassword=" "$CONFIG_FILE" 2>/dev/null; then
        ${pkgs.gnused}/bin/sed -i "s|^registerpassword=.*|registerpassword=$REGISTER_PASSWORD|" "$CONFIG_FILE"
      else
        echo "registerpassword=$REGISTER_PASSWORD" >> "$CONFIG_FILE"
      fi

      # Update or add serverpassword
      if grep -q "^serverpassword=" "$CONFIG_FILE" 2>/dev/null; then
        ${pkgs.gnused}/bin/sed -i "s|^serverpassword=.*|serverpassword=$SERVER_PASSWORD|" "$CONFIG_FILE"
      else
        echo "serverpassword=$SERVER_PASSWORD" >> "$CONFIG_FILE"
      fi

      # Set SuperUser password BEFORE starting server
      ${pkgs.mumble}/bin/murmurd -ini "$CONFIG_FILE" -supw "$SUPERUSER_PASSWORD" || true

      # Start murmur
      exec ${pkgs.mumble}/bin/murmurd -ini "$CONFIG_FILE"
    '';
  };

  # Firewall - only allow Mumble port
  networking.firewall = {
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
    # Do NOT open Ice ports (6502) or DBus
  };
}
