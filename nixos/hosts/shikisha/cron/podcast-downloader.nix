{ config, pkgs, ... }:
let
  downloadDir = "/mnt/unraid/Other/Podcasts/Linux Unplugged";

  pythonEnv = pkgs.python3.withPackages (ps: [ ps.feedparser ps.requests ]);

  podcastDownloader = pkgs.writeScript "podcast-downloader.py" ''
    #!${pythonEnv}/bin/python3
    import sys, os, re, feedparser, requests
    from datetime import datetime

    FEED_URL_FILE = sys.argv[1]
    DOWNLOAD_DIR  = sys.argv[2]
    STATE_FILE    = sys.argv[3]

    def read_feed_url(path):
        with open(path) as f: return f.read().strip()

    def load_downloaded(state_file):
        if not os.path.exists(state_file): return set()
        with open(state_file) as f:
            return set(line.strip() for line in f if line.strip())

    def save_guid(state_file, guid):
        with open(state_file, "a") as f: f.write(guid + "\n")

    def sanitize_filename(title):
        safe = re.sub(r"[^\w\s\-\.]", "", title)
        return re.sub(r"\s+", " ", safe).strip()[:200]

    def get_date_prefix(entry):
        if hasattr(entry, "published_parsed") and entry.published_parsed:
            return datetime(*entry.published_parsed[:6]).strftime("%Y-%m-%d")
        return datetime.utcnow().strftime("%Y-%m-%d")

    def find_audio_enclosure(entry):
        for enc in getattr(entry, "enclosures", []):
            if getattr(enc, "type", "").startswith("audio/") or enc.href.split("?")[0].endswith(".mp3"):
                return enc
        return None

    def download_episode(url, dest_path):
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        tmp = dest_path + ".part"
        with requests.get(url, stream=True, timeout=120) as r:
            r.raise_for_status()
            with open(tmp, "wb") as f:
                for chunk in r.iter_content(chunk_size=262144): f.write(chunk)
        os.rename(tmp, dest_path)
        print(f"Downloaded: {dest_path}")

    feed_url   = read_feed_url(FEED_URL_FILE)
    downloaded = load_downloaded(STATE_FILE)
    feed       = feedparser.parse(feed_url)

    if feed.bozo and not feed.entries:
        print(f"ERROR: feed parse failed: {feed.bozo_exception}", file=sys.stderr)
        sys.exit(1)

    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    new_count = 0

    for entry in reversed(feed.entries):
        guid = getattr(entry, "id", None) or getattr(entry, "link", None)
        if not guid or guid in downloaded: continue

        enc = find_audio_enclosure(entry)
        if enc is None:
            save_guid(STATE_FILE, guid); continue

        dest = os.path.join(DOWNLOAD_DIR,
            f"{get_date_prefix(entry)} - {sanitize_filename(entry.get('title', 'untitled'))}.mp3")

        if os.path.exists(dest):
            save_guid(STATE_FILE, guid); downloaded.add(guid); continue

        try:
            download_episode(enc.href, dest)
            save_guid(STATE_FILE, guid); downloaded.add(guid); new_count += 1
        except Exception as e:
            print(f"ERROR downloading '{entry.get('title')}': {e}", file=sys.stderr)

    print(f"Done. {new_count} new episode(s) downloaded.")
  '';
in {
  sops.secrets."podcast/feed-url" = {
    owner = "root";
    mode  = "0400";
  };

  systemd.timers.podcast-downloader = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Wed *-*-* 06:00:00 UTC";
      Persistent = "true";
      Unit       = "podcast-downloader.service";
    };
  };

  systemd.services.podcast-downloader = {
    description = "Download new Linux Unplugged podcast episodes";
    after       = [ "network-online.target" "mnt-unraid-Other.mount" ];
    wants       = [ "network-online.target" ];
    path   = [ pkgs.rsync pkgs.openssh ];
    script = ''
      ${podcastDownloader} \
        "${config.sops.secrets."podcast/feed-url".path}" \
        "${downloadDir}" \
        "/var/lib/podcast-downloader/downloaded.txt"

      rsync -a --mkpath \
        "${downloadDir}/" \
        "sean@wopr-0:/media/qnap/Podcasts/LinuxUnplugged/"
    '';
    serviceConfig = {
      Type           = "oneshot";
      User           = "root";
      StateDirectory = "podcast-downloader";
    };
  };
}
