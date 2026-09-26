# AGENTS.md — working in `nixos-configs`

Orientation for an AI agent (or a human) making changes here. Read this before
editing; it encodes conventions that are enforced socially and by git hooks, not
by the Nix build.

## What this repo is

Declarative NixOS, nix-darwin, and home-manager configuration.

Almost everything here is either evaluated by Nix or is a repo-level gate. The
handful of exceptions are noted in *Layout* below.

That rule decides where a new artifact belongs: if Nix can evaluate it, it goes
here. If it is only read by a human or an agent, it goes in the knowledge base
(`hermes-bot/homelab-kb` on Forgejo — see *Referential docs*).

## Host inventory

The source of truth is `flake.nix`, not this list — read it before relying on
either. Configurations as of `0eac443`:

| Config | Platform | Notes |
|---|---|---|
| `nx-01` | NixOS x86_64 | zen kernel, virtualisation |
| `seanix` | NixOS x86_64 | gaming + productivity; off/on daily |
| `shikisha` | NixOS x86_64 | homelab server: Grafana, Prometheus, Loki, Authentik, Home Assistant, LubeLogger |
| `voyager` | NixOS x86_64 | virtualisation, X server |
| `whale` | NixOS x86_64 | GNOME desktop, cage kiosk session |
| `badgey` | NixOS x86_64 | runs `services.hermes-fileshare` (Hermes agent host) |
| `cerritos` | NixOS x86_64 | libvirt guest (static IP on the default NAT network) |
| `stargazer` | NixOS x86_64 | ThinkPad P1 Gen 3; config is `nixos/hosts/workstations/stargazer.nix` |
| `seair` | nix-darwin aarch64 | M2 MacBook Air |
| `defiant` | nix-darwin aarch64 | M4 MacBook Air |
| `droid` | nix-on-droid | Pixel 8 |
| `patrick` | home-manager | non-NixOS Linux target |

> The README historically listed `seanvy`. **No such configuration exists** —
> it was named only in the README. Do not treat the README as the inventory.

## Layout

```
flake.nix              entrypoint: inputs, nixosConfigurations, darwinConfigurations,
                       homeConfigurations, nixOnDroidConfigurations
nixos/<host>.nix       per-host system config (imported by flake.nix)
nixos/hosts/<host>/    per-host extras (host-specific modules, cron, facter.json)
nixos/modules/<domain>/  reusable modules, grouped by domain:
                       audio backups desktop disks gaming hardware homelab i18n
                       monitoring network scripts shell system user virtualisation
nixos/hardware-configuration/  generated hardware files (impure eval)
darwin/                nix-darwin tree: base.nix, hosts/, modules/
home/                  home-manager: home.nix + per-host profiles + modules/
flakes/                vendored/patched package flakes (bcachefs, cosmic-applets, fish)
scripts/               helper scripts referenced by configs
sops-nix/              sops secrets + agent reference docs
checks/                repo gates (see below)
```

`nixos/share/sounds/` holds artifacts Nix *does* consume (`boot-sound-seanix.nix`
references `../share/sounds/mac-boot-chime.wav`), so they belong here. The four
`nixos/share/*.yaml` files are lima VM templates — **no tracked file references
them**; they are kept for manual `limactl start ./<file>.yaml` use.

## Gates: what will reject your change

### 1. `checks/pre-push` — direct pushes to `main` are blocked
`core.hooksPath = checks`, so this runs on every push. It refuses any push to
`refs/heads/main` or `refs/heads/master` and rejects buildEnv-incompatible
derivations via `checks/lint-buildenv-paths.py`.

**Work on a feature branch and open a PR. Always.** `main` additionally requires
one human approval; there is no auto-merge.

### 2. `checks/lint-buildenv-paths.py`
Flags derivations that would break a `home.packages` merge through `buildEnv`.
See the `nixos-derivation-packaging` skill for the underlying constraint.

## Conventions

**Comments.** One line of *intent*, only where the code is not self-evident.

- **No rationale, no "why", no links** — those belong in the PR body. This is a
  recurring complaint; err strongly toward fewer comments.
- **Zero comments for self-evident code or deletion sites.**
- Applies to Nix *and* everything else.

**Secrets.** Every value is user-created and sops-encrypted. Never generate,
commit, echo, or log a secret value.

- Encrypted secrets: `sops-nix/`, schema in `.sops.yaml`.
- Decryption key `keys.txt` is deliberately untracked (see README §Secrets).
- Reference credentials **by path**, never inline.
- When a secret is created or moved, tell the user *what*, *where*, and *why*.

**Referential docs.** Runbooks, access procedures, and host rebuild kits do **not**
go in this repo — `docs/` is gitignored. They live in the Forgejo knowledge base
`hermes-bot/homelab-kb` (`shikisha:3002`, private; `hermes-bot` and `patrick`
both have owner access). Start at its `README.md` for the index and the
belongs-here rule.

**Scratch files.** Use `/opt/data/cache/`, never `scripts/`.

## Verifying a change

The toolchain is Nix; there is no `nix` binary in the agent container by default.
Use `/opt/data/nix-portable`.

```bash
# Parse-only, fast:
/opt/data/nix-portable nix-instantiate --parse nixos/modules/<path>.nix

# Full evaluation of a host (proves modules render):
/opt/data/nix-portable nix eval --impure --no-write-lock-file --raw --expr \
  'let f = builtins.getFlake (toString /opt/data/nixos-configs);
   in f.packages.x86_64-linux.nixosConfigurations.shikisha.drvPath'
```

Hardware configs need `--impure`; the flake is not hermetic for those.

**Do not claim a change works because it parses.** Evaluate the host config that
consumes the module, and check the specific setting you touched actually
renders. For monitoring changes, confirm the scrape target and alert rules appear
in the evaluated config — a syntactically valid module that silently drops a
rule is the failure mode that matters here.

## PR workflow

- Branch from `main`; one focused change per PR.
- Push with a GitHub token from the `GITHUB_PAT` env var (`sprjr-bot`,
  `public_repo` scope — can open PRs, cannot push `main` or merge).
- If push auth misbehaves, `~/.gitconfig`'s `credential.helper` for github.com
  overrides `-c credential.helper` and returns a stale token. Defeat it with
  `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null`.
- PR body carries the *why* — that is where rationale belongs, not in comments.
