{ config, ... }:

{
  # Loki. Fully declared here rather than via services.loki.configFile so the config is
  # versioned with the flake. dataDir defaults to /var/lib/loki; path_prefix points at it
  # instead of the upstream example's /tmp/loki, which does not survive a reboot.
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        # Bind wide; the tailscale0-scoped firewall below is the boundary.
        http_listen_address = "0.0.0.0";
        http_listen_port = 3100;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = 9096;
      };

      common = {
        instance_addr = "127.0.0.1";
        path_prefix = "/var/lib/loki";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
        replication_factor = 1; # upstream default is 3; single binary needs 1
        ring.kvstore.store = "inmemory";
      };

      query_range.results_cache.cache.embedded_cache = {
        enabled = true;
        max_size_mb = 100;
      };

      schema_config.configs = [
        {
          from = "2020-10-24";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      # Retention is only enforced when the compactor runs with retention_enabled.
      compactor = {
        working_directory = "/var/lib/loki/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };

      limits_config = {
        retention_period = "720h"; # 30d
        allow_structured_metadata = true;
        volume_enabled = true; # log-volume histogram in Grafana Explore
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      analytics.reporting_enabled = false;
    };
  };

  # Prometheus. The self-scrape job is "prometheus-server" because "prometheus" is also a
  # hostname in this flake and would make {job="prometheus"} ambiguous.
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "0.0.0.0";
    retentionTime = "30d";
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        # Tailscale MagicDNS names. The workstations sleep, so up{} flaps for them by design.
        static_configs = [
          {
            targets = [
              "shikisha:9100"
              "nx-01:9100"
              "prometheus:9100"
              "voyager:9100"
              "seanix:9100"
              "wopr-0:9100"
            ];
          }
        ];
      }
      {
        job_name = "prometheus-server";
        static_configs = [ { targets = [ "127.0.0.1:9090" ]; } ];
      }
      {
        job_name = "loki";
        static_configs = [ { targets = [ "127.0.0.1:3100" ]; } ];
      }
      {
        job_name = "grafana";
        static_configs = [ { targets = [ "127.0.0.1:3000" ]; } ];
      }
    ];
  };

  # Declared alongside services.grafana so the grafana user exists when sops-nix chowns these.
  sops.secrets = {
    "grafana/admin-password" = {
      owner = "grafana";
      mode = "0400";
      restartUnits = [ "grafana.service" ];
    };
    "grafana/secret-key" = {
      owner = "grafana";
      mode = "0400";
      restartUnits = [ "grafana.service" ];
    };
    # Client secret of the Authentik OAuth2/OIDC provider named "grafana".
    "grafana/oauth-client-secret" = {
      owner = "grafana";
      mode = "0400";
      restartUnits = [ "grafana.service" ];
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        # Caddy runs on a separate host, so loopback-only will not work.
        http_addr = "0.0.0.0";
        http_port = 3000;
        # Absolute URLs (share links, alert links, future OAuth redirects) are built from
        # these, so they describe what the browser sees through Caddy, not this host.
        domain = "grafana.rawliyosh.com";
        root_url = "https://grafana.rawliyosh.com/";
        # enforce_domain would reject requests whose Host header differs from `domain`,
        # breaking direct access over Tailscale.
        enforce_domain = false;
      };
      security = {
        admin_user = "admin";
        # $__file{} keeps the secrets out of the world-readable Nix store.
        admin_password = "$__file{${config.sops.secrets."grafana/admin-password".path}}";
        secret_key = "$__file{${config.sops.secrets."grafana/secret-key".path}}";
        cookie_secure = true; # the browser sees HTTPS even though the backend hop is plain
        # "strict" would withhold the oauth_state cookie on the cross-site redirect back
        # from Authentik, failing every OAuth login with a state mismatch.
        cookie_samesite = "lax";
      };
      # Gates the local signup form only; OAuth signup is auth.generic_oauth.allow_sign_up.
      users.allow_sign_up = false;
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      # Authentik SSO. The local login form is deliberately left enabled so a broken or
      # unreachable Authentik does not lock the admin account out.
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authentik";
        icon = "signin";
        # Creates a Grafana user on first successful OAuth login.
        allow_sign_up = true;
        # Must match the Client ID on the Authentik provider; Authentik generates a random
        # one by default, so it has to be overridden there to this value.
        client_id = "grafana";
        client_secret = "$__file{${config.sops.secrets."grafana/oauth-client-secret".path}}";
        # offline_access is what makes Authentik issue the refresh token used below.
        scopes = "openid email profile offline_access";
        auth_url = "https://auth.rawliyosh.com/application/o/authorize/";
        token_url = "https://auth.rawliyosh.com/application/o/token/";
        api_url = "https://auth.rawliyosh.com/application/o/userinfo/";
        # Unlike the others, the end-session endpoint is keyed by application slug.
        signout_redirect_url = "https://auth.rawliyosh.com/application/o/grafana/end-session/";
        use_pkce = true;
        use_refresh_token = true;
        # JMESPath over the userinfo claims. Requires the provider to emit a groups claim,
        # which the default "authentik default OAuth Mapping: OpenID 'profile'" scope does.
        role_attribute_path =
          "contains(groups, 'grafana-admins') && 'Admin' "
          + "|| contains(groups, 'grafana-editors') && 'Editor' "
          + "|| 'Viewer'";
        # false means a user matching no branch above still logs in; the path already ends
        # in a 'Viewer' fallback, so this only covers a missing groups claim.
        role_attribute_strict = false;
        # Lets the Admin branch grant server admin, not just org admin.
        allow_assign_grafana_admin = true;
      };
    };

    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        # uids are pinned so committed dashboard JSON can reference them by uid.
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            uid = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            uid = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        # A store path, so provisioned dashboards cannot be saved from the UI. To add a
        # community dashboard, fetch it with pkgs.fetchurl pinned by revision+hash, strip its
        # __inputs block and rewrite ${DS_*} to a pinned uid, then combine with pkgs.linkFarm.
        providers = [
          {
            name = "nixos";
            options.path = ./dashboards;
          }
        ];
      };
    };
  };

  # 3000 for the external Caddy host, 3100/9090 for API access. Nothing is opened to the LAN
  # or the internet from this host.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    3000
    3100
    9090
  ];
}
