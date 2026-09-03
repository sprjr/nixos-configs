{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

# Radicale (CalDAV) "next events" waybar widget. Available to ANY host running the
# Hyprland session (laptop-home / desktop-home both import ./hyprland), not gated
# by host. Reaches Radicale on shikisha over tailscale (radicale.nix opens 5232 on
# interfaces.tailscale0). Requires the `radicale/password` sops secret to be
# decryptable on the host (same pattern as the ha_token widget).
let
  cfg = config.patrick.home.hyprland;

  caldavUrl = "http://shikisha:5232";
  caldavUser = "patrick";
  passwordPath = config.sops.secrets."radicale/password".path;

  # Python with the libs needed to parse iCalendar + expand RRULE recurrences.
  calPython = pkgs.python3.withPackages (ps: [
    ps.icalendar
    ps.python-dateutil
  ]);

  waybar-calendar = pkgs.writeScript "waybar-calendar" ''
    #!${calPython}/bin/python3
    import base64
    import datetime
    import json
    import os
    import urllib.request
    import xml.etree.ElementTree as ET

    from icalendar import Calendar
    from dateutil.rrule import rrulestr
    from dateutil.tz import tzlocal

    CALDAV_URL = "${caldavUrl}"
    CALDAV_USER = "${caldavUser}"
    PASSWORD_PATH = "${passwordPath}"
    COLLECTIONS = ["personal", "work"]
    MAX_EVENTS = 3

    CAL_NS = "urn:ietf:params:xml:ns:caldav"

    REPORT_BODY = (
        '<?xml version="1.0"?>'
        '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">'
        "<d:prop><d:getetag/><c:calendar-data/></d:prop>"
        '<c:filter><c:comp-filter name="VCALENDAR">'
        '<c:comp-filter name="VEVENT"/></c:comp-filter></c:filter>'
        "</c:calendar-query>"
    ).encode()

    def fetch_calendar_data(collection):
        url = f"{CALDAV_URL}/{CALDAV_USER}/{collection}/"
        req = urllib.request.Request(url, data=REPORT_BODY, method="REPORT")
        req.add_header("Content-Type", "application/xml")
        req.add_header("Depth", "1")
        with open(PASSWORD_PATH) as f:
            password = f.read().strip()
        token = base64.b64encode(f"{CALDAV_USER}:{password}".encode()).decode()
        req.add_header("Authorization", f"Basic {token}")
        with urllib.request.urlopen(req, timeout=10) as resp:
            xml = resp.read()
        root = ET.fromstring(xml)
        out = []
        for data_el in root.iter(f"{{{CAL_NS}}}calendar-data"):
            if data_el.text:
                out.append(data_el.text)
        return out

    def dt_to_aware(dt):
        if isinstance(dt, datetime.datetime):
            if dt.tzinfo is None:
                return dt.replace(tzinfo=tzlocal())
            return dt.astimezone(tzlocal())
        return datetime.datetime(dt.year, dt.month, dt.day, tzinfo=tzlocal())

    def occurrences(vevent, now):
        summary = str(vevent.get("SUMMARY", "(no title)"))
        dtstart = vevent.get("DTSTART")
        if dtstart is None:
            return
        start = dt_to_aware(dtstart.dt)
        rrule = vevent.get("RRULE")
        if rrule is None:
            if start >= now:
                yield (start, summary)
            return
        rule = rrulestr(rrule.to_ical().decode(), dtstart=start)
        for occ in rule:
            if occ >= now:
                yield (occ, summary)
                if occ > now + datetime.timedelta(days=60):
                    break

    def fmt_time(dt):
        now = datetime.datetime.now(tzlocal())
        if dt.date() == now.date():
            day = "Today"
        elif dt.date() == (now + datetime.timedelta(days=1)).date():
            day = "Tomorrow"
        else:
            day = dt.strftime("%a %d %b")
        if dt.hour == 0 and dt.minute == 0:
            return f"{day}"
        return f"{day} {dt:%H:%M}"

    def main():
        now = datetime.datetime.now(tzlocal())
        upcoming = []
        for col in COLLECTIONS:
            try:
                for raw in fetch_calendar_data(col):
                    try:
                        cal = Calendar.from_ical(raw)
                    except Exception:
                        continue
                    for comp in cal.walk("VEVENT"):
                        for start, summary in occurrences(comp, now):
                            upcoming.append((start, summary, col))
            except Exception:
                continue
        upcoming.sort(key=lambda x: x[0])
        upcoming = upcoming[:MAX_EVENTS]

        if not upcoming:
            print(json.dumps({"text": "", "tooltip": "no upcoming events"}))
            return

        text = upcoming[0][0].strftime("%a %d %b %H:%M")
        lines = []
        for start, summary, col in upcoming:
            lines.append(f"  {fmt_time(start)}  {summary}")
        tooltip = "Next events:\n" + "\n".join(lines)
        print(json.dumps({"text": text, "tooltip": tooltip}))

    if __name__ == "__main__":
        main()
  '';
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    sops.secrets."radicale/password" = { };

    home.packages = [ waybar-calendar ];
  };
}
