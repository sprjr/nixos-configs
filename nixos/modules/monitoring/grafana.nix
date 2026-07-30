{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Stable series color per host. Without this Grafana assigns palette-classic colors by series
  # index within each panel, so a sleeping host dropping out of one query shifts every colour
  # after it on that panel only, and a host reads differently graph to graph.
  hostColors = {
    shikisha = "green";
    "nx-01" = "blue";
    prometheus = "purple";
    voyager = "orange";
    seanix = "red";
    "wopr-0" = "yellow";
  };

  # Matches both legend shapes in use: the Prometheus panels are {{instance}} ("shikisha:9100"),
  # the Loki panel is {{host}} ("shikisha"). Fully anchored, because Grafana's byRegexp matcher
  # has used both .test() and full-match semantics across versions.
  hostColorOverrides = lib.mapAttrsToList (host: color: {
    matcher = {
      id = "byRegexp";
      options = "/^${host}(:[0-9]+)?$/";
    };
    properties = [
      {
        id = "color";
        value = {
          mode = "fixed";
          fixedColor = color;
        };
      }
    ];
  }) hostColors;

  # Timeseries panels only: the "Hosts up" stat panel colors by up/down threshold and the
  # "Recent errors" logs panel has no field config.
  colorByHost =
    dashboard:
    dashboard
    // {
      panels = map (
        panel:
        if panel.type == "timeseries" then
          lib.recursiveUpdate panel {
            fieldConfig = {
              defaults.color.mode = "palette-classic"; # fallback for a host not in hostColors
              overrides = hostColorOverrides;
            };
          }
        else
          panel
      ) dashboard.panels;
    };

  homelabDashboard = colorByHost (
    builtins.fromJSON (builtins.readFile ./dashboards/homelab-overview.json)
  );

  # services-overview passes through untouched: its series are blackbox probe URLs, not hosts.
  dashboardDir = pkgs.linkFarm "grafana-dashboards" [
    {
      name = "homelab-overview.json";
      path = pkgs.writeText "homelab-overview.json" (builtins.toJSON homelabDashboard);
    }
    {
      name = "services-overview.json";
      path = ./dashboards/services-overview.json;
    }
  ];

  # grafana.ini's $__file{} substitutes one file per value, so every URL kept out of the store
  # needs its own rendered file. Grafana trims surrounding whitespace when reading them.
  urlFile = content: {
    owner = "grafana";
    mode = "0400";
    restartUnits = [ "grafana.service" ];
    inherit content;
  };
in

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
      # Blackbox targets live in a sops-rendered file so the URLs stay out of the Nix store.
      # This is file_sd rather than prometheus' scrape_config_files: the NixOS module builds
      # prometheus.yml from a closed set of keys (global, scrape_configs, remote_*, rule_files,
      # alerting) and cannot emit scrape_config_files at all. file_sd gets the same property —
      # targets read at runtime, so adding one needs no rebuild — via a supported option.
      {
        job_name = "blackbox";
        metrics_path = "/probe";
        params.module = [ "http_2xx" ];
        file_sd_configs = [
          { files = [ config.sops.templates."prometheus-blackbox.yml".path ]; }
        ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:9115";
          }
        ];
      }
    ];
    # promtool runs inside the build sandbox and cannot see the sops-rendered file_sd file, so a
    # full `promtool check config` fails on the missing path. Syntax-only skips referenced-file
    # validation; the scrape config itself is still checked.
    checkConfig = "syntax-only";
  };

  # configFile takes a path (types.path), not an inline attrset — there is no `configuration`
  # option on this exporter. Generating it into the store also gets it config-checked at build
  # time by `blackbox_exporter --config.check` (enableConfigCheck, default true).
  services.prometheus.exporters.blackbox = {
    enable = true;
    port = 9115;
    configFile = (pkgs.formats.yaml { }).generate "blackbox-exporter.yml" {
      modules.http_2xx = {
        prober = "http";
        timeout = "10s";
        http = {
          valid_http_versions = [
            "HTTP/1.1"
            "HTTP/2.0"
          ];
          follow_redirects = true;
          preferred_ip_protocol = "ip4";
          tls_config.insecure_skip_verify = false;
        };
      };
    };
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
    # Public hostname Caddy serves this instance on, e.g. grafana.example.com. Read directly by
    # grafana.ini, hence the grafana ownership; the other URLs derive from templates below.
    "grafana/domain" = {
      owner = "grafana";
      mode = "0400";
      restartUnits = [ "grafana.service" ];
    };
    # Scheme and host of the Authentik instance, no trailing slash and no path.
    "grafana/authentik-base-url" = { };
    "monitoring/blackbox-targets/immich" = { };
    "monitoring/blackbox-targets/authentik" = { };
    "monitoring/blackbox-targets/media" = { };
    "monitoring/blackbox-targets/ike" = { };
    # Full ntfy topic URL for alert notifications, without a query string.
    "monitoring/ntfy/grafana-alerts-url" = { };
  };

  # Rendered at runtime by sops-nix; the blackbox job above loads it via file_sd_configs. This is
  # a file_sd target-group list, not a scrape config — job structure stays in scrapeConfigs so it
  # remains versioned; only the URLs are secret. Prometheus re-reads this every 5m by default.
  # Add a new service: add a sops secret and a new `- <placeholder>` line here.
  sops.templates."prometheus-blackbox.yml" = {
    owner = "prometheus";
    mode = "0400";
    content = ''
      - targets:
          - ${config.sops.placeholder."monitoring/blackbox-targets/immich"}
          - ${config.sops.placeholder."monitoring/blackbox-targets/authentik"}
          - ${config.sops.placeholder."monitoring/blackbox-targets/media"}
          - ${config.sops.placeholder."monitoring/blackbox-targets/ike"}
    '';
  };

  # root_url and the four OIDC endpoints are derived from the two secrets above rather than
  # stored individually, so rotating a domain touches one sops value. The Authentik paths are
  # fixed by its OAuth2 provider; only the end-session endpoint is keyed by application slug.
  sops.templates."grafana-root-url" = urlFile "https://${config.sops.placeholder."grafana/domain"}/";
  sops.templates."grafana-oauth-auth-url" = urlFile "${
    config.sops.placeholder."grafana/authentik-base-url"
  }/application/o/authorize/";
  sops.templates."grafana-oauth-token-url" = urlFile "${
    config.sops.placeholder."grafana/authentik-base-url"
  }/application/o/token/";
  sops.templates."grafana-oauth-api-url" = urlFile "${
    config.sops.placeholder."grafana/authentik-base-url"
  }/application/o/userinfo/";
  sops.templates."grafana-oauth-signout-url" = urlFile "${
    config.sops.placeholder."grafana/authentik-base-url"
  }/application/o/grafana/end-session/";

  # Contact points are the only alerting resource holding a secret, so they are the only one
  # rendered at runtime; rules and the policy tree stay inline in Nix below. The NixOS module
  # symlinks `provision.alerting.contactPoints.path` into the provisioning directory without
  # copying, so a /run path stays out of the store — the symlink is dangling at build time and
  # resolves once sops-nix has rendered the file.
  # ?template=grafana makes ntfy render the webhook JSON into a readable notification server
  # side (ntfy >= 2.12); drop it and the raw payload becomes the message body.
  sops.templates."grafana-contact-points.yaml" = {
    owner = "grafana";
    mode = "0400";
    restartUnits = [ "grafana.service" ];
    content = ''
      apiVersion: 1
      contactPoints:
        - orgId: 1
          name: ntfy
          receivers:
            - uid: ntfy-alerts
              type: webhook
              disableResolveMessage: false
              settings:
                url: ${config.sops.placeholder."monitoring/ntfy/grafana-alerts-url"}?template=grafana
                httpMethod: POST
    '';
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
        domain = "$__file{${config.sops.secrets."grafana/domain".path}}";
        root_url = "$__file{${config.sops.templates."grafana-root-url".path}}";
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
        auth_url = "$__file{${config.sops.templates."grafana-oauth-auth-url".path}}";
        token_url = "$__file{${config.sops.templates."grafana-oauth-token-url".path}}";
        api_url = "$__file{${config.sops.templates."grafana-oauth-api-url".path}}";
        # Unlike the others, the end-session endpoint is keyed by application slug.
        signout_redirect_url = "$__file{${config.sops.templates."grafana-oauth-signout-url".path}}";
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
        # A store path, so provisioned dashboards cannot be saved from the UI. dashboardDir is
        # the linkFarm built above: homelab-overview.json has its per-host color overrides
        # injected from hostColors, which is why the committed JSON carries "overrides": [].
        # To add a community dashboard, fetch it with pkgs.fetchurl pinned by revision+hash,
        # strip its __inputs block and rewrite ${DS_*} to a pinned uid, then add it to the farm.
        providers = [
          {
            name = "nixos";
            options.path = dashboardDir;
          }
        ];
      };

      # Everything provisioned here is read-only in the UI. Removing a rule from this file does
      # not delete it from Grafana's database — that needs a `deleteRules` entry with its uid.
      alerting = {
        contactPoints.path = config.sops.templates."grafana-contact-points.yaml".path;

        # The policy tree is a single resource: this replaces it wholesale, including the
        # default grafana-default-email route.
        policies.settings = {
          apiVersion = 1;
          policies = [
            {
              orgId = 1;
              receiver = "ntfy";
              group_by = [
                "alertname"
                "instance"
              ];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "6h";
            }
          ];
        };

        rules.settings = {
          apiVersion = 1;
          groups = [
            {
              orgId = 1;
              name = "availability";
              folder = "Alerts";
              interval = "1m";
              rules = [
                {
                  uid = "probe-down";
                  title = "Service probe failing";
                  condition = "C";
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 600;
                        to = 0;
                      };
                      datasourceUid = "prometheus";
                      model = {
                        refId = "A";
                        expr = ''probe_success{job="blackbox"}'';
                        instant = true;
                      };
                    }
                    {
                      refId = "B";
                      datasourceUid = "__expr__";
                      model = {
                        refId = "B";
                        type = "reduce";
                        reducer = "last";
                        expression = "A";
                      };
                    }
                    {
                      refId = "C";
                      datasourceUid = "__expr__";
                      model = {
                        refId = "C";
                        type = "threshold";
                        expression = "B";
                        conditions = [
                          {
                            type = "query";
                            evaluator = {
                              type = "lt";
                              params = [ 1 ];
                            };
                          }
                        ];
                      };
                    }
                  ];
                  for = "5m";
                  noDataState = "NoData";
                  execErrState = "Error";
                  labels.severity = "critical";
                  # The instance label is the probed URL, i.e. one of the sops-held blackbox
                  # targets. It reaches ntfy and Grafana's database, neither of which is public.
                  annotations.summary = "{{ $labels.instance }} has failed its HTTP probe";
                }
                {
                  uid = "host-down";
                  title = "Host down";
                  condition = "C";
                  data = [
                    {
                      refId = "A";
                      relativeTimeRange = {
                        from = 600;
                        to = 0;
                      };
                      datasourceUid = "prometheus";
                      model = {
                        refId = "A";
                        # Restricted to the always-on hosts: the workstations sleep, so up{}
                        # flapping for them is expected and would alert every night.
                        expr = ''up{job="node", instance=~"shikisha:9100|wopr-0:9100"}'';
                        instant = true;
                      };
                    }
                    {
                      refId = "B";
                      datasourceUid = "__expr__";
                      model = {
                        refId = "B";
                        type = "reduce";
                        reducer = "last";
                        expression = "A";
                      };
                    }
                    {
                      refId = "C";
                      datasourceUid = "__expr__";
                      model = {
                        refId = "C";
                        type = "threshold";
                        expression = "B";
                        conditions = [
                          {
                            type = "query";
                            evaluator = {
                              type = "lt";
                              params = [ 1 ];
                            };
                          }
                        ];
                      };
                    }
                  ];
                  for = "10m";
                  noDataState = "NoData";
                  execErrState = "Error";
                  labels.severity = "critical";
                  annotations.summary = "{{ $labels.instance }} has stopped reporting to Prometheus";
                }
              ];
            }
          ];
        };
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
