{ config, pkgs, lib, ... }:

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
    defaults.email = "your-email@example.com";

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

    welcometext = "Welcome to my Mumble server!";
    bandwidth = 130000;
    users = 100;

    registerName = "My Mumble Server";
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

  # Modify service to inject passwords before starting
  systemd.services.murmur = {
    serviceConfig = {
      SupplementaryGroups = [ "murmur" ];
      LogsDirectory = "murmur";
      ReadWritePaths = [ "/var/log/murmur" "/run/murmur" ];
    };

    # Run this BEFORE the main service starts
    serviceConfig.ExecStartPre = lib.mkAfter [
      (pkgs.writeShellScript "inject-murmur-passwords" ''
        set -euo pipefail

        # Read passwords from sops
        REGISTER_PASSWORD=$(cat ${config.sops.secrets.mumble-register-password.path})
        SERVER_PASSWORD=$(cat ${config.sops.secrets.mumble-server-password.path})
        SUPERUSER_PASSWORD=$(cat ${config.sops.secrets.mumble-superuser-password.path})

        CONFIG_FILE=/run/murmur/murmurd.ini

        # Wait for config to exist
        timeout=10
        while [ ! -f "$CONFIG_FILE" ] && [ $timeout -gt 0 ]; do
          sleep 0.1
          timeout=$((timeout - 1))
        done

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
      '')
    ];
  };

  # Set SuperUser password after service starts (one-time)
  systemd.services.murmur-set-superuser = {
    description = "Set Murmur SuperUser Password";
    after = [ "murmur.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Wait for murmur to be ready
      sleep 2

      # Read SuperUser password
      SUPERUSER_PASSWORD=$(cat ${config.sops.secrets.mumble-superuser-password.path})

      # Set it (using the actual working murmur command from the service)
      ${pkgs.murmur}/bin/murmurd -ini /run/murmur/murmurd.ini -supw "$SUPERUSER_PASSWORD" || true
    '';
  };

  # Firewall configuration - only allow Mumble port
  networking.firewall = {
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
  };
}{ config, pkgs, lib, ... }:

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

  # Modify service to inject passwords before starting
  systemd.services.murmur = {
    serviceConfig = {
      SupplementaryGroups = [ "murmur" ];
      LogsDirectory = "murmur";
      ReadWritePaths = [ "/var/log/murmur" "/run/murmur" ];
    };

    # Run this BEFORE the main service starts
    serviceConfig.ExecStartPre = lib.mkAfter [
      (pkgs.writeShellScript "inject-murmur-passwords" ''
        set -euo pipefail

        # Read passwords from sops
        REGISTER_PASSWORD=$(cat ${config.sops.secrets.mumble-register-password.path})
        SERVER_PASSWORD=$(cat ${config.sops.secrets.mumble-server-password.path})
        SUPERUSER_PASSWORD=$(cat ${config.sops.secrets.mumble-superuser-password.path})

        CONFIG_FILE=/run/murmur/murmurd.ini

        # Wait for config to exist
        timeout=10
        while [ ! -f "$CONFIG_FILE" ] && [ $timeout -gt 0 ]; do
          sleep 0.1
          timeout=$((timeout - 1))
        done

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
      '')
    ];
  };

  # Set SuperUser password after service starts (one-time)
  systemd.services.murmur-set-superuser = {
    description = "Set Murmur SuperUser Password";
    after = [ "murmur.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Wait for murmur to be ready
      sleep 2

      # Read SuperUser password
      SUPERUSER_PASSWORD=$(cat ${config.sops.secrets.mumble-superuser-password.path})

      # Set it (using the actual working murmur command from the service)
      ${pkgs.murmur}/bin/murmurd -ini /run/murmur/murmurd.ini -supw "$SUPERUSER_PASSWORD" || true
    '';
  };

  # Firewall configuration - only allow Mumble port
  networking.firewall = {
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
  };
}
