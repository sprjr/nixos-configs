{
  config,
  lib,
  ...
}:

let
  cfg = config.services.vikunja.oidc;
  envPrefix = "VIKUNJA_AUTH_OPENID_PROVIDERS_${lib.toUpper cfg.providerKey}";
in
{
  options.services.vikunja.oidc = {
    enable = lib.mkEnableOption "Authentik OIDC single sign-on for Vikunja (implies services.vikunja.enable)";

    providerKey = lib.mkOption {
      type = lib.types.str;
      default = "authentik";
      description = ''
        OpenID provider key. Also the `<provider>` segment of the callback URL
        `/api/v1/auth/openid/<provider>/callback`, which the Authentik provider
        must whitelist as a redirect URI.
      '';
    };

    providerName = lib.mkOption {
      type = lib.types.str;
      default = "Authentik";
      description = "Label shown on the login button.";
    };

    baseUrl = lib.mkOption {
      type = lib.types.str;
      example = "https://authentik.example.com";
      description = ''
        Authentik base URL. The OIDC issuer passed to Vikunja is
        `<baseUrl>/application/o/<providerKey>/`.
      '';
    };

    publicHost = lib.mkOption {
      type = lib.types.str;
      example = "vikunja.example.com";
      description = "Hostname Vikunja is published on; used for its public URL and OIDC redirects.";
    };

    publicScheme = lib.mkOption {
      type = lib.types.enum [
        "http"
        "https"
      ];
      default = "https";
      description = "Scheme Vikunja is published on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3456;
      description = "TCP port the Vikunja API listens on.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.baseUrl != "";
        message = "services.vikunja.oidc.baseUrl must be set when OIDC is enabled.";
      }
    ];

    services.vikunja = {
      enable = true;
      inherit (cfg) port;
      frontendScheme = cfg.publicScheme;
      frontendHostname = cfg.publicHost;
      settings.auth.openid = {
        enabled = true;
        providers.${cfg.providerKey} = {
          name = cfg.providerName;
          authurl = "${cfg.baseUrl}/application/o/${cfg.providerKey}/";
          scope = "openid profile email";
        };
      };
    };

    sops.secrets."vikunja/service-secret" = { };
    sops.secrets."vikunja/oidc-client-id" = { };
    sops.secrets."vikunja/oidc-client-secret" = { };

    # Client ID and client secret come from env: Vikunja's file-based secret
    # lookup does not cover openid provider credentials.
    sops.templates."vikunja-env" = {
      mode = "0400";
      content = ''
        VIKUNJA_SERVICE_SECRET=${config.sops.placeholder."vikunja/service-secret"}
        ${envPrefix}_CLIENTID=${config.sops.placeholder."vikunja/oidc-client-id"}
        ${envPrefix}_CLIENTSECRET=${config.sops.placeholder."vikunja/oidc-client-secret"}
      '';
    };

    services.vikunja.environmentFiles = [ config.sops.templates."vikunja-env".path ];

    # The manager reads the EnvironmentFile as root, so it needs no owner.
    systemd.services.vikunja = {
      after = [ "sops-secrets-rendered.service" ];
      requires = [ "sops-secrets-rendered.service" ];
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.port ];
  };
}
