{ pkgs, ... }:
let
  vaultDir = "/Users/patrick/Documents/Obsidian/SXR/Daily Notes";

  carryScript = pkgs.writeScript "obsidian-daily-carry.py" ''
    #!${pkgs.python3}/bin/python3
    import sys
    from datetime import date, timedelta
    from pathlib import Path

    vault_dir = Path(sys.argv[1])
    today     = date.today()
    yesterday = today - timedelta(days=1)

    yesterday_file = vault_dir / f"{yesterday}.md"
    today_file     = vault_dir / f"{today}.md"

    def extract_section_lines(text, header):
        lines = text.splitlines()
        in_section = False
        result = []
        for line in lines:
            if line.rstrip() == header:
                in_section = True
                continue
            if in_section:
                if line.startswith("## "):
                    break
                result.append(line)
        while result and not result[-1].strip():
            result.pop()
        return result

    if not yesterday_file.exists():
        print(f"No yesterday note: {yesterday_file}", file=sys.stderr)
        raise SystemExit(0)

    tomorrow_lines = extract_section_lines(yesterday_file.read_text(), "## Tomorrow")
    carried = [l for l in tomorrow_lines if l.strip()]

    if not carried:
        print("Nothing to carry forward.", file=sys.stderr)
        raise SystemExit(0)

    if today_file.exists():
        lines = today_file.read_text().splitlines(keepends=True)
        result = []
        injected = False
        for line in lines:
            result.append(line)
            if not injected and line.rstrip() == "## Today":
                for item in carried:
                    result.append(item + "\n")
                injected = True
        if not injected:
            result.append("\n## Today\n")
            for item in carried:
                result.append(item + "\n")
        today_file.write_text("".join(result))
    else:
        today_file.write_text(
            "## Today\n" + "\n".join(carried) + "\n\n## Tomorrow\n\n## Later (Include Date)\n"
        )

    print(f"Carried {len(carried)} item(s): {yesterday} Tomorrow -> {today} Today")
  '';
in
{
  launchd.agents.obsidian-daily-carry = {
    enable = true;
    config = {
      Label = "com.patrick.obsidian-daily-carry";
      ProgramArguments = [
        "${carryScript}"
        "${vaultDir}"
      ];
      StartCalendarInterval = [
        {
          Hour = 8;
          Minute = 15;
        }
      ];
      StandardOutPath = "/tmp/obsidian-daily-carry.log";
      StandardErrorPath = "/tmp/obsidian-daily-carry.log";
    };
  };
}
