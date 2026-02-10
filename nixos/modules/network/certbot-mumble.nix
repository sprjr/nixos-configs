{ config, pkgs, ... }:

{
  # Sops secrets
  sops.secrets = {
    acme-email = {
      owner = "root";
      mode = "0400";
    };
    cloudflare-api-token = {
      owner = "root";
      mode = "0400";
    };
    mumble-register-password = {
      owner = "murmur";
      mode = "0400";
    };
  };

  # ACME / Let's Encrypt - use placeholder email
  security.acme = {
    acceptTerms = true;
    defaults.email = "placeholder@example.com";  # Placeholder, will be overridden

    certs."talk.rawlinson.xyz" = {
      group = "murmur";
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets.cloudflare-api-token.path;
      postRun = "systemctl reload murmur.service";
    };
  };

  # Override ACME service to use real email from sops
  systemd.services."acme-talk.rawlinson.xyz" = {
    serviceConfig = {
      LoadCredential = "email:${config.sops.secrets.acme-email.path}";
    };
    script = pkgs.lib.mkForce ''
      EMAIL=$(cat $CREDENTIALS_DIRECTORY/email)
      export EMAIL
      ${pkgs.writeShellScript "acme-start" ''
        # Run certbot with email from credential
        exec ${config.security.acme.package}/bin/certbot \
          certonly \
          --non-interactive \
          --agree-tos \
          --email "$EMAIL" \
          --dns-cloudflare \
          --dns-cloudflare-credentials ${config.sops.secrets.cloudflare-api-token.path} \
          -d talk.rawlinson.xyz \
          --cert-name talk.rawlinson.xyz \
          --work-dir /var/lib/acme/.lego/talk.rawlinson.xyz \
          --config-dir /var/lib/acme/talk.rawlinson.xyz \
          --logs-dir /var/log/acme/talk.rawlinson.xyz
      ''}
    '';
  };

  # Murmur (Mumble Server)
  services.murmur = {
    enable = true;

    welcometext = "Welcome to the Jungle";
    bandwidth = 130000;
    users = 100;

    registerName = "The Messiest and Wettest Mumble Server";
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

}
