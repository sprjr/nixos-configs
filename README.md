# nixos-configs

Declarative NixOS, nix-darwin, and home-manager configuration for my machines.

> AI-assisted changes are made to this repo in a reviewed, careful context.
> Agents: read [`AGENTS.md`](AGENTS.md) first — it documents the gates and
> conventions this repo enforces.

## Configurations

`flake.nix` is the source of truth. Current targets:

### NixOS

| Config | Machine |
|---|---|
| `nx-01` | desktop |
| `seanix` | gaming + productivity workstation |
| `shikisha` | homelab server (Grafana, Prometheus, Loki, Authentik, Home Assistant, LubeLogger) |
| `voyager` | desktop |
| `whale` | desktop (GNOME + kiosk session) |
| `badgey` | Hermes agent host |
| `cerritos` | libvirt guest |
| `stargazer` | ThinkPad P1 Gen 3 |

### Darwin

| Config | Machine |
|---|---|
| `seair` | M2 MacBook Air |
| `defiant` | M4 MacBook Air |

### Other

| Config | Target |
|---|---|
| `droid` | Pixel 8 (nix-on-droid) |
| `patrick` | home-manager, non-NixOS Linux |

The names vaguely relate to their function, but just as well might not.

## Usage

### NixOS

```bash
nixos-rebuild switch --flake github:sprjr/nixos-configs#seanix
```

Hardware-specific information is present in these configurations, so it may need
`--impure` or other flags as needed.

### macOS

```bash
nix run "github:LNL7/nix-darwin#packages.aarch64-darwin.darwin-rebuild" -- switch \
  --flake github:sprjr/nixos-configs#seair
```

You may need to add `--extra-experimental-features nix-command --extra-experimental-features flakes`
before the `--`, depending on your setup, and it may be `--impure`.

### Other Linux distributions

Assuming flakes are enabled:

```bash
nix run "github:sprjr/nixos-configs#homeConfigurations.patrick.activationPackage"
```

## Secrets

Secrets are encrypted with sops (`sops-nix/sops.yaml`). Decryption requires the
age key at `/home/patrick/.config/sops/age/keys.txt`, which is deliberately not
tracked.

On a fresh install the key is absent, so no secrets are decrypted on first boot
and `sops-secrets-rendered` fails after 120 s. Provide it at deploy time:

```bash
nix run github:nix-community/nixos-anywhere -- --flake .#<host> \
  --target-host root@<host-ip> \
  --extra-files ./extra-files
```

with `extra-files/home/patrick/.config/sops/age/keys.txt` in place. `--extra-files`
preserves file modes, so restrict it first:

```bash
chmod 600 extra-files/home/patrick/.config/sops/age/keys.txt
```

Files are copied root-owned, which is sufficient: `setupSecrets` runs as root at
activation, so the key does not need to be owned by `patrick`.

To keep the key out of the deploy artifacts entirely, omit it from
`--extra-files` and copy it onto the target after installation.

## Repository map

```
flake.nix              entrypoint: host configurations, inputs, dev shell
AGENTS.md              conventions + gates for agents (and humans)
README.md              this file
nixos/<host>.nix       per-host system configuration
nixos/hosts/<host>/    per-host extras (modules, cron, facter.json)
nixos/modules/<domain>/  reusable modules by domain
nixos/hardware-configuration/  generated hardware files
darwin/                nix-darwin tree
home/                  home-manager profiles and modules
flakes/                vendored/patched package flakes
scripts/               helper scripts referenced by configs
sops-nix/              sops secrets and agent reference docs
checks/                pre-push gates
```

## Contributing

- `checks/pre-push` blocks direct pushes to `main`; branch and open a PR.
- `main` requires one human approval — no auto-merge.
- Comments: one line of intent only, and none where the code is self-evident.

## Documentation

Runbooks, host rebuild kits, and access procedures are **not** in this repo.
They live in the private Forgejo knowledge base `hermes-bot/homelab-kb`
(`shikisha:3002`) — start at its `README.md` for the index.
