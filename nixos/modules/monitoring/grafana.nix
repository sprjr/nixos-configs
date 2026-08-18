{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Stable per-host colors; without this, a sleeping host dropping out shifts all colors after it.
  hostColors = {
    shikisha = "green";
    "nx-01" = "blue";
    voyager = "orange";
    seanix = "red";
    "wopr-0" = "yellow";
    "opnsense-fairview" = "white";
    seair = "super-light-blue";
    defiant = "light-purple";
    badgey = "dark-green";
  };

  # Anchored regex matches both {{instance}} ("host:9100") and {{host}} ("host") legend shapes.
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

  colorByHost =
    dashboard:
    dashboard
    // {
      panels = map (
        panel:
        if panel.type == "timeseries" then
          lib.recursiveUpdate panel {
            fieldConfig = {
              defaults.color.mode = "palette-classic";
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

  nixStateDashboard = colorByHost (builtins.fromJSON (builtins.readFile ./dashboards/nix-state.json));

  syncthingDashboard = colorByHost (
    builtins.fromJSON (builtins.readFile ./dashboards/syncthing.json)
  );

  # services-overview skips colorByHost: its series are probe URLs, not hosts.
  dashboardDir = pkgs.linkFarm "grafana-dashboards" [
    {
      name = "homelab-overview.json";
      path = pkgs.writeText "homelab-overview.json" (builtins.toJSON homelabDashboard);
    }
    {
      name = "services-overview.json";
      path = ./dashboards/services-overview.json;
    }
    {
      name = "nix-state.json";
      path = pkgs.writeText "nix-state.json" (builtins.toJSON nixStateDashboard);
    }
    {
      name = "syncthing.json";
      path = pkgs.writeText "syncthing.json" (builtins.toJSON syncthingDashboard);
    }
  ];

  # One sops-rendered file per $__file{} substitution; Grafana trims whitespace on read.
  urlFile = content: {
    owner = "grafana";
    mode = "0400";
    restartUnits = [ "grafana.service" ];
    inherit content;
  };
in

{
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
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
        replication_factor = 1; # single-binary mode requires 1
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

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };

      limits_config = {
        retention_period = "720h"; # 30d
        allow_structured_metadata = true;
        volume_enabled = true;
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      analytics.reporting_enabled = false;
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "0.0.0.0";
    retentionTime = "30d";
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "shikisha:9100"
              "nx-01:9100"
              "voyager:9100"
              "seanix:9100"
              "wopr-0:9100"
              "opnsense-fairview:9100"
              "seair:9100"
              "defiant:9100"
              "badgey:9100"
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
      # file_sd because the NixOS module can't emit scrape_config_files; URLs are sops secrets.
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
      {
        job_name = "blackbox-responsive";
        metrics_path = "/probe";
        params.module = [ "http_responsive" ];
        file_sd_configs = [
          { files = [ config.sops.templates."prometheus-blackbox-responsive.yml".path ]; }
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
    # syntax-only: full check fails on sops-rendered file_sd paths missing in the sandbox.
    checkConfig = "syntax-only";
  };

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
      # Services that require auth return 401 to unauthenticated probes; accept any status.
      modules.http_responsive = {
        prober = "http";
        timeout = "10s";
        http = {
          valid_http_versions = [
            "HTTP/1.1"
            "HTTP/2.0"
          ];
          valid_status_codes = [
            200
            201
            204
            301
            302
            401
            403
          ];
          follow_redirects = false;
          preferred_ip_protocol = "ip4";
          tls_config.insecure_skip_verify = false;
        };
      };
    };
  };

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
    "grafana/oauth-client-id" = {
      owner = "grafana";
      mode = "0400";
      restartUnits = [ "grafana.service" ];
    };
    "grafana/oauth-client-secret" = {
      owner = "grafana";
      mode = "0400";
      restartUnits = [ "grafana.service" ];
    };
    "grafana/domain" = {
      owner = "grafana";
      mode = "0400";
      restartUnits = [ "grafana.service" ];
    };
    "grafana/authentik-base-url" = { };
    "monitoring/blackbox-targets/immich" = { };
    "monitoring/blackbox-targets/authentik" = { };
    "monitoring/blackbox-targets/media" = { };
    "monitoring/blackbox-targets/ike" = { };
    "monitoring/ntfy/grafana-alerts-url" = { };
    "monitoring/ha-webhook/grafana-alerts-url" = { };
  };

  sops.templates."prometheus-blackbox.yml" = {
    owner = "prometheus";
    mode = "0400";
    content = ''
      - targets:
          - ${config.sops.placeholder."monitoring/blackbox-targets/immich"}
          - ${config.sops.placeholder."monitoring/blackbox-targets/authentik"}
          - ${config.sops.placeholder."monitoring/blackbox-targets/ike"}
    '';
  };

  sops.templates."prometheus-blackbox-responsive.yml" = {
    owner = "prometheus";
    mode = "0400";
    content = ''
      - targets:
          - ${config.sops.placeholder."monitoring/blackbox-targets/media"}
    '';
  };

  # OIDC URLs derived from two base secrets so rotating a domain touches one sops value.
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

  # ?template=grafana makes ntfy render the webhook JSON into a readable notification.
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
            - uid: awtrix-ha-alerts
              type: webhook
              disableResolveMessage: false
              settings:
                url: ${config.sops.placeholder."monitoring/ha-webhook/grafana-alerts-url"}
                httpMethod: POST
    '';
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "$__file{${config.sops.secrets."grafana/domain".path}}";
        root_url = "$__file{${config.sops.templates."grafana-root-url".path}}";
        # false: enforce_domain would break direct Tailscale access.
        enforce_domain = false;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets."grafana/admin-password".path}}";
        secret_key = "$__file{${config.sops.secrets."grafana/secret-key".path}}";
        cookie_secure = true;
        # "strict" breaks OAuth: state cookie withheld on Authentik redirect.
        cookie_samesite = "lax";
      };
      users.allow_sign_up = false;
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      # Authentik SSO; local login left enabled as fallback.
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authentik";
        icon = "signin";
        allow_sign_up = true;
        client_id = "$__file{${config.sops.secrets."grafana/oauth-client-id".path}}";
        client_secret = "$__file{${config.sops.secrets."grafana/oauth-client-secret".path}}";
        scopes = "openid email profile offline_access";
        auth_url = "$__file{${config.sops.templates."grafana-oauth-auth-url".path}}";
        token_url = "$__file{${config.sops.templates."grafana-oauth-token-url".path}}";
        api_url = "$__file{${config.sops.templates."grafana-oauth-api-url".path}}";
        signout_redirect_url = "$__file{${config.sops.templates."grafana-oauth-signout-url".path}}";
        use_pkce = true;
        use_refresh_token = true;
        # JMESPath; requires Authentik provider to emit a groups claim.
        role_attribute_path =
          "contains(groups, 'grafana-admins') && 'Admin' "
          + "|| contains(groups, 'grafana-editors') && 'Editor' "
          + "|| 'Viewer'";
        role_attribute_strict = false;
        allow_assign_grafana_admin = true;
      };
    };

    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
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
        providers = [
          {
            name = "nixos";
            options.path = dashboardDir;
          }
        ];
      };

      alerting = {
        contactPoints.path = config.sops.templates."grafana-contact-points.yaml".path;

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
                        expr = ''probe_success{job=~"blackbox.*"}'';
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
                        # Only always-on hosts; workstations sleep and would false-alarm.
                        expr = ''up{job="node", instance=~"shikisha:9100|wopr-0:9100|badgey:9100"}'';
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

  # Tailscale-only: Grafana, Loki, Prometheus.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    3000
    3100
    9090
  ];
}
