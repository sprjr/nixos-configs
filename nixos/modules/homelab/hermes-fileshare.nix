{ lib, pkgs, config, ... }:

let
  cfg = config.services.hermes-fileshare;
  shareDir = "/var/lib/hermes-agent/workspace/fileshare";
in
{
  options.services.hermes-fileshare = {
    enable = lib.mkEnableOption "Hermes ad-hoc file exchange directory";

    ziplineUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://shikisha:3221";
      description = "Zipline base URL used by the outbox uploader.";
    };

    ziplineTtl = lib.mkOption {
      type = lib.types.str;
      default = "1d";
      description = "x-zipline-deletes-at value: uploaded links stop resolving after this.";
    };

    agentUid = lib.mkOption {
      type = lib.types.int;
      default = 10000;
      description = "UID the hermes-agent container runs as; owns the ingest side of the share.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."hermes-agent/zipline-token" = { };

    sops.templates."hermes-fileshare-env" = {
      mode = "0400";
      content = ''
        ZIPLINE_TOKEN=${config.sops.placeholder."hermes-agent/zipline-token"}
      '';
    };

    systemd.services.hermes-fileshare = {
      description = "Ingest dropped files for Hermes and push the outbox to Zipline";
      startAt = "*:0/2";
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.templates."hermes-fileshare-env".path;
      };
      environment = {
        ZIPLINE_URL = cfg.ziplineUrl;
        ZIPLINE_TTL = cfg.ziplineTtl;
      };
      path = with pkgs; [ coreutils findutils gnugrep curl ];
      script = ''
        set -eu

        install -d -m 0755 -o ${toString cfg.agentUid} -g ${toString cfg.agentUid} \
          ${shareDir}/ingested ${shareDir}/outbox

        # Root-written drops land root-owned and the container only fixes ownership
        # at boot, so hand them to the agent here. Only the ingest target is
        # walked recursively; the drop dir itself stays cheap to scan.
        find ${shareDir} -maxdepth 1 -mindepth 1 -type f \
          -exec mv -f -t ${shareDir}/ingested {} +

        if find ${shareDir}/ingested \( ! -uid ${toString cfg.agentUid} -o ! -gid ${toString cfg.agentUid} \) \
             -print -quit | grep -q .; then
          chown -R ${toString cfg.agentUid}:${toString cfg.agentUid} ${shareDir}/ingested
        fi

        for f in ${shareDir}/outbox/*; do
          [ -f "$f" ] || continue
          # A failed upload must not abort the run nor drop the file: it retries next tick.
          if url=$(curl -fsS -X POST "$ZIPLINE_URL/api/upload" \
            -H "Authorization: $ZIPLINE_TOKEN" \
            -H "x-zipline-deletes-at: $ZIPLINE_TTL" \
            -H "x-zipline-original-name: true" \
            -H "x-zipline-no-json: true" \
            -F "file=@$f")
          then
            printf '%s\t%s\t%s\n' "$(date -Is)" "$(basename "$f")" "$url" \
              >> ${shareDir}/zipline-urls.txt
            rm -f "$f"
          fi
        done

        chown ${toString cfg.agentUid}:${toString cfg.agentUid} ${shareDir}/zipline-urls.txt 2>/dev/null || true
      '';
    };
  };
}
