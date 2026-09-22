#!/usr/bin/env python3
"""Reject single-file derivations placed in an environment package list."""
import re
import sys
from pathlib import Path

BARE = ("writeShellScript", "writeScript", "writeTextFile", "writeText")
ALT = "|".join(sorted(BARE, key=len, reverse=True))
BUILDER_RE = re.compile(r"\b(?:pkgs\.)?(?:%s)(?!\w)" % ALT)
BINDING_RE = re.compile(r"(?P<name>[A-Za-z_][\w'-]*)\s*=\s*(?:pkgs\.)?(?:%s)(?!\w)" % ALT)
LIST_RE = re.compile(
    r"(?:\bsystemPackages|\benvironment\.packages|\bhome\.packages|\bpackages)"
    r"\s*=\s*(?:with\s+[\w.'-]+\s*;\s*)?\["
)


def blank(text):
    """Erase comments and strings in-place so bracket matching is reliable."""
    out = list(text)
    i, n = 0, len(text)
    while i < n:
        two = text[i : i + 2]
        if two == "/*":
            j = text.find("*/", i + 2)
            j = n if j == -1 else j + 2
        elif text[i] == "#":
            j = text.find("\n", i)
            j = n if j == -1 else j
        elif two == "''":
            j = i + 2
            while j < n:
                if text[j : j + 2] == "''" and text[j + 2 : j + 3] not in ("'", "$"):
                    j += 2
                    break
                j += 2 if text[j : j + 3] in ("'''", "''$") else 1
        elif text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            j = min(j + 1, n)
        else:
            i += 1
            continue
        for k in range(i, min(j, n)):
            if out[k] != "\n":
                out[k] = " "
        i = j
    return "".join(out)


def bracket_end(s, start):
    depth = 0
    for i in range(start, len(s)):
        if s[i] in "[({":
            depth += 1
        elif s[i] in "])}":
            depth -= 1
            if depth == 0:
                return i
    return -1


def check(path):
    raw = path.read_text(encoding="utf-8", errors="replace")
    code = blank(raw)
    bare = {}
    for m in BINDING_RE.finditer(code):
        bare.setdefault(m.group("name"), (m.start(), m.group(0).split("=")[-1].strip()))

    found = []
    for m in LIST_RE.finditer(code):
        open_at = code.index("[", m.start())
        end = bracket_end(code, open_at)
        if end == -1:
            continue
        body = code[open_at:end]
        attr = "systemPackages" if "systemPackages" in m.group(0) else "packages"
        base = raw.count("\n", 0, open_at) + 1
        for fm in BUILDER_RE.finditer(body):
            found.append((base + body.count("\n", 0, fm.start()), attr, fm.group(0), "inline"))
        for name, (off, builder) in bare.items():
            if re.search(r"(?<![\w'-])%s(?![\w'-])" % re.escape(name), body):
                found.append((raw.count("\n", 0, off) + 1, attr, name, builder))
    return found


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    hits = []
    for path in sorted(root.rglob("*.nix")):
        if ".git" not in path.parts:
            hits += [(path, *f) for f in check(path)]
    for path, line, attr, token, how in hits:
        print(f"{path}:{line}: {token} ({how}) in {attr}", file=sys.stderr)
    if hits:
        print(f"\nFAIL: {len(hits)} bare-file derivation(s) in an environment package list.", file=sys.stderr)
        print(
            "buildEnv merges directories only - use writeShellScriptBin, "
            "writeScriptBin, or writeShellApplication.",
            file=sys.stderr,
        )
        return 1
    print("OK: no bare-file derivations in environment package lists")
    return 0


if __name__ == "__main__":
    sys.exit(main())
