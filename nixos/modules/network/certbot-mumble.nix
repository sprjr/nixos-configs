{ config, pkgs, lib, ... }:

let
  # Create a wrapper script that sets passwords then starts murmur
  murmurWrapper = pkgs.writeShellScript "murmur-wrapper" ''
    set -euo pipefail

    # Read passwords from sops
    REGISTER_PASSWORD=$(cat ${config.sops.secrets.mumble-register-password.path})
    SERVER_PASSWORD=$(cat ${config.sops.secrets.mumble-server-password.path})
    SUPERUSER_PASSWORD=$(cat ${config.sops.secrets.mumble-superuser-password.path})

    CONFIG_FILE=/run/murmur/murmurd.ini

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

    # Set SuperUser password
    ${pkgs.mumble}/bin/murmurd -ini "$CONFIG_FILE" -supw "$SUPERUSER_PASSWORD" || true

    # Start murmur
    exec ${pkgs.mumble}/bin/murmurd -ini "$CONFIG_FILE"
  '';
in
{
  # Sops secrets configuration
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

  # ACME / Let's Encrypt certificate configuration
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

  # Murmur (Mumble Server) configuration
  services.murmur = {
    enable = true;

    welcometext = "Welcome to the Jungle";
    bandwidth = 130000;
    users = 100;

    registerName = "The Messiest, Wettest Mumble Server";
    registerHostname = "talk.rawlinson.xyz";
    registerPassword = "";  # Will be injected from sops
    password = "";  # Will be injected from sops

    sslCert = "/var/lib/acme/talk.rawlinson.xyz/fullchain.pem";
    sslKey = "/var/lib/acme/talk.rawlinson.xyz/key.pem";

    extraConfig = ''
      allowhtml=true
      database=/var/lib/murmur/murmur.sqlite

      # Disable remote admin interfaces for security
      ice=""

      # Additional security settings
      allowping=false
      sendversion=false
    '';
  };

  # Override systemd service to inject passwords
  systemd.services.murmur = {
    serviceConfig = {
      SupplementaryGroups = [ "murmur" ];
      LogsDirectory = "murmur";
      ReadWritePaths = [ "/var/log/murmur" ];
      ExecStart = lib.mkForce murmurWrapper;
    };
  };

  # Firewall configuration - only allow Mumble port
  networking.firewall = {
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
  };
}
