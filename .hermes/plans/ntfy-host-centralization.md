# ntfy Server Host Centralization — Audit & Migration Plan

**Repo:** `sprjr/nixos-configs` (local clone at `/opt/data/nixos-configs`, branch `main`)
**Date:** 2026-09-12
**Status:** PLAN ONLY — no files edited, no commits made.

## Summary

The ntfy server is referenced in this repository in **exactly two places by a
hardcoded Tailscale IP** (`http://100.119.239.121:55455/...`). Both occurrences
live in **orphaned modules** (no host imports them). All *live* ntfy consumers
(`comin-notify`, `frigate-notify`, `grafana`) already read their full ntfy URL
from **SOPS secrets** (`monitoring/ntfy/*-url`), which are also encrypted in
`sops-nix/sops.yaml`.

Because the server is about to move to a **NEW Tailscale IP**, the two hardcoded
URLs must be centralised. The single source of truth chosen is a **module-level
Nix variable** in a new shared module, injected via each host's `flake.nix`
`modules` list. Everything else (secrets-based consumers) only needs a secret
re-encryption — no code change.

---

## PART 1 — Complete Inventory

### A. Hardcoded ntfy server by IP address (Tailscale `100.x`)

| # | File | Line | Exact current snippet |
|---|------|------|----------------------|
| 1 | `nixos/modules/network/scripts/ip_check.nix` | 12 | `ntfyTopic = "http://100.119.239.121:55455/rawliyosh-administration-notification-network-hso"` |
| 2 | `nixos/modules/scripts/docker-healthcheck-restart.nix` | 24 | `  http://100.119.239.121:55455/rawliyosh-administration-notification-network-hso` (single `curl -s -X POST` argument) |

**Both are the same server endpoint** `100.119.239.121:55455`, port `55455`
(ntfy), topic `rawliyosh-administration-notification-network-hso`.

### B. ntfy consumers that already use SOPS secrets (NO hardcoded host — for awareness)

These do **not** contain an IP, but each embeds the full `http://<host>:<port>/<topic>`
URL *inside an encrypted sops value*. They must be re-encrypted with the new IP,
but no Nix source edit is required.

| File | Line(s) | Sops secret consumed |
|------|---------|----------------------|
| `nixos/modules/system/comin-notify.nix` | 6, 13–14, 79 | `monitoring/ntfy/comin-url` |
| `nixos/modules/homelab/frigate-notify.nix` | 8, 15–16, 54 | `monitoring/ntfy/frigate-events-url` |
| `nixos/modules/monitoring/grafana.nix` | 380, 434 | `monitoring/ntfy/grafana-alerts-url` |
| `sops-nix/sops.yaml` | 73–76 | `monitoring.ntfy.{comin-url, grafana-alerts-url, frigate-events-url}` |

### C. ntfy server / listener config

- **No ntfy server listen/bind config exists anywhere in this repo** — no
  `services.ntfy`, no container/deployment manifest, no port-forward for `55455`,
  no entry in `nixos/modules/virtualisation/containers/docker-compose.yml`
  (that compose file is gitea/postgres only). The ntfy server itself runs
  elsewhere (external container/host, presumed on the Tailnet) and is addressed
  by the Tailscale IP `100.119.239.121:55455`. **It must NOT move with this
  repo** — only the client-side references do.

### D. Host module import mapping (who is affected)

- **`comin-notify`** → imported by hosts: **trixos** (flake 166), **prometheus**
  (230), **seanix** (263), **shikisha** (314), **whale** (368), **badgey** (397),
  **cerritos** (435). (voyager has it commented out at 336; nx-01 does not import it.)
- **`frigate-notify`** → **badgey** (flake 408).
- **`grafana.nix`** → **shikisha** (flake 306).
- **`ip_check.nix`** (hardcoded #1) → **NOT imported by any host** (confirmed:
  no reference in `flake.nix`, `nixos/`, or `home/`). **Orphaned.**
- **`docker-healthcheck-restart.nix`** (hardcoded #2) → **NOT imported by any host.**
  **Orphaned.**

---

## PART 2 — Migration Plan

### Step 1 — Introduce the single source of truth

**Chosen location:** a new shared NixOS module variable, because:
- This repo has **no `lib`/constants/flake.lib** pattern to reuse (confirmed).
- The natural existing pattern is a **module injected per-host via `flake.nix`**
  (all other reusable settings work this way).
- A SOPS secret can't be the *sole* source of truth for the **host** — the two
  non-secret scripts also need it, and they must not be world-readable-with-secret.

**Create:** `nixos/modules/system/ntfy-host.nix`

```nix
# Central, single definition of the ntfy server location.
# Change this ONE value when the ntfy server's Tailscale IP/hostname moves.
{ config, lib, pkgs, ... }:

{
  # Single source of truth for the ntfy server + shared alert topic.
  # (Hostname preferred over a raw IP so it survives IP churn; resolve via
  #  MagicDNS / /etc/hosts / sops before this lands.)
  ntfy.alertUrl =
    "http://100.119.239.121:55455/rawliyosh-administration-notification-network-hso";
  # Keep the raw base host separate so non-alert topics can reuse it later:
  ntfy.baseUrl = "http://100.119.239.121:55455";
}
```

> **Recommendation:** when the server migrates, prefer **changing the value to a
> stable Tailscale MagicDNS hostname** (e.g. `http://ntfy.<tailnet>.ts.net:55455`)
> rather than pinning a *new* IP. That converts future migrations to a no-op.
> If that isn't possible, put the new IP here — this file becomes the one edit
> point.

### Step 2 — Consume the variable in each audit finding

#### Finding A1 — `nixos/modules/network/scripts/ip_check.nix`

- **Edit:** import the central module value and interpolate it into the script.
  Change function signature from:
  ```nix
  { config, pkgs, ... }:
  ```
  to:
  ```nix
  { config, lib, pkgs, ... }:
  ```
  and replace line 12:
  ```nix
  ntfyTopic = "http://100.119.239.121:55455/rawliyosh-administration-notification-network-hso"
  ```
  with:
  ```nix
  ntfyTopic = config.ntfy.alertUrl        # or "${config.ntfy.baseUrl}/<topic>"
  ```
- **Required wiring (in `flake.nix`):** add `./nixos/modules/system/ntfy-host.nix`
  AND `./nixos/modules/network/scripts/ip_check.nix` to the target host's
  `modules = [ ... ]` list (currently it is orphaned — see Step 4).

#### Finding A2 — `nixos/modules/scripts/docker-healthcheck-restart.nix`

- **Edit:** change function signature (line 1) from `{ pkgs, ... }:` to
  `{ config, lib, pkgs, ... }:` and replace the hardcoded URL at line 24
  (the tail of the `curl -s -X POST` command) with a reference to the central value:
  ```nix
  ## before
  $logs" \
        http://100.119.239.121:55455/rawliyosh-administration-notification-network-hso

  ## after
  $logs" \
        ${config.ntfy.alertUrl}
  ```
- **Required wiring (in `flake.nix`):** add `./nixos/modules/system/ntfy-host.nix`
  AND `./nixos/modules/scripts/docker-healthcheck-restart.nix` to the target
  host's `modules = [ ... ]` list (also orphaned — see Step 4).

#### Step 3 — Re-encrypt the SOPS secrets that embed the old IP

No source edit — but the encrypted values **must** be updated with the new
server address (host + port), otherwise `comin-notify`, `frigate-notify`, and
Grafana alerting keep posting to the old IP.

- **Path:** `sops-nix/sops.yaml`, keys `monitoring.ntfy.comin-url`,
  `monitoring.ntfy.grafana-alerts-url`, `monitoring.ntfy.frigate-events-url`
  (and `monitoring.ha-webhook.grafana-alerts-url` if the webhook is also
  host-bound).
- **Mechanism:** `nix run .#sops` / `sops --config sops-nix/sops.yaml edit sops-nix/sops.yaml`
  (or `update-keys` if only the value hostname changes). The new values must be
  `<new-host>:<new-port>/<topic>`. **This is a human/secret-owner action** — the
  agent never writes plaintext or fabricates secret values (per `github-repo-management`).
- **Edge:** these are used with `sops.templates`/`sops.placeholder` in
  `grafana.nix`; re-rendering happens automatically on rebuild.

### Step 4 — Mark the orphaned modules as stale in-file (decision: keep, flag)

**Decision (Patrick, 2026-09-12):** keep both modules, do **not** delete and do
**not** resurrect. Mark each as currently stale directly in the file so any
future reader knows the hardcoded IP is dead and must be centralized before use.

The two modules that actually contain the hardcoded IP are **not currently
imported by any host** in `flake.nix` — the functionality (public-IP change
alerting, docker-unhealthy restart alerting) is **dead code** today.

For each orphaned module, add a leading `#` comment block (next to the existing
`{ config, lib, pkgs, ... }:` function header) such as:

```nix
# STALE / DEAD CODE — not imported by any host in flake.nix.
# The IP below is hardcoded and points at the OLD ntfy server.
# If/when resurrected, centralize it: consume config.ntfy.alertUrl / baseUrl
# from nixos/modules/system/ntfy-host.nix instead of pinning an IP here.
# See .hermes/plans/ntfy-host-centralization.md
```

- **`nixos/modules/network/scripts/ip_check.nix`** — add the stale block above
  the function header. Leave the module otherwise untouched and un-imported.
- **`nixos/modules/scripts/docker-healthcheck-restart.nix`** — same: add the
  stale comment block; leave un-imported.

> If either module is later intentionally made live, it must be wired to the
> central `ntfy-host.nix` module in the same commit (see Step 2) or it will
> fail to evaluate (`config.ntfy` undefined) and still reference the old IP.
> Until then, neither is running on any host and the IP may already be stale.

### Step 5 — Configs that regenerate / rebuild

| Component | Trigger | Action |
|-----------|---------|--------|
| `ip-monitor.service` + `ip-monitor.timer` | `nixos-rebuild` on host that imports `ip_check.nix` | systemd units + embedded script re-render |
| `docker-health-watcher` (the `curl …` watcher script) | `nixos-rebuild` on the docker host | script re-renders with new `${config.ntfy.alertUrl}` |
| `comin-notify.service`/`.timer` | re-encrypt sops + `nixos-rebuild` on each comin host | `monitoring/ntfy/comin-url` sops file re-rendered; unit reads it at runtime |
| `frigate-notify.service` | re-encrypt sops + `nixos-rebuild` on badgey | secret file re-rendered |
| `grafana.service` | re-encrypt sops + `nixos-rebuild` on shikisha | `grafana-contact-points.yaml` template re-rendered; unit restarted (declared via `restartUnits`) |
| sops secret files | `nixos-rebuild` (sops-nix pulls new value) | all of the above re-read their secret at runtime |

**Home-manager:** no home-manager config references ntfy (checked
`home/…/*.nix` — the only `notify-send` hits are volume/brightness keybinds,
unrelated). No home-manager rebuild required.

**Comin deployment order:** changes to `flake.nix` + these modules deploy via
comin when merged to `main` (hosts with `comin.nix`: nx-01, prometheus, seanix,
shikisha, badgey, whale). `trixos` has **no comin** — requires a manual
`nixos-rebuild` on the machine. The sops re-encryption must be done **before**
the code change lands, or the new rebuilds will render old-IP secrets.

---

## PART 3 — Edge Cases & Things That Break If Only The "Main Machine" Moves

1. **The ntfy server is NOT defined in this repo.** It is an external/container
   service at `100.119.239.121:55455`. This repo only *addresses* it. Moving the
   server (new Tailscale IP) breaks **every** consumer below unless they are all
   updated together — a code change on one host never suffices.

2. **Multiple hosts reference the same ntfy server** via sops secrets:
   - `comin-notify` → **trixos, prometheus, seanix, shikisha, whale, badgey,
     cerritos** all publish to `monitoring/ntfy/comin-url`.
   - `frigate-notify` (badgey) and `grafana` (shikisha) similarly.
   - If only `shikisha` (the presumed "main machine" running Grafana) is updated,
     the comin hosts (trixos, prometheus, seanix, whale, badgey, cerritos) will
     still post to the dead IP. **The sops secret change is global.**

3. **Sops secrets encrypt the full URL.** A raw `grep` for the IP finds the
   plaintext occurrences, but the *real consumers* read the old IP from encrypted
   values. Missing the sops re-encryption is the #1 silent-breakage risk.

4. **Raw Tailscale IP vs hostname.** Prefer moving the central value to a
   MagicDNS/hostname (`*.ts.net`). A raw new IP still breaks again on the *next*
   migration. If a hostname is used, confirm it resolves from **all** consumer
   hosts (MagicDNS across the tailnet), including non-comin `trixos`, the
   `cerritos` VM (NAT-isolated — needs the host resolvable via tailscale routes or
   a static fallback), and any darwin hosts if later wired.

5. **Orphaned modules.** `ip_check.nix` and `docker-healthcheck-restart.nix`
   hold the only *plaintext* IPs but are not imported. If they are resurrected
   later without wiring `ntfy-host.nix`, they fail to evaluate (`config.ntfy`
   undefined) — so wire/delete them in the same commit as the central module.

6. **Non-Nix / out-of-repo consumers** (mobile ntfy app, webhooks, other machines
   not in this repo) that use `http://100.119.239.121:55455/...` will break on the
   migration regardless of this repo; they must be updated out-of-band. Check
   any external alerting (e.g. HA automations, `frigate-hermes` is Telegram/HA,
   not ntfy — unaffected).

7. **Port `55455`.** The central value must bind host+port together (`:55455`),
   since the server may change port in the same migration. Keep the port in the
   base URL, not hardcoded in consumers.

8. **`networking.hostName`-based consumers** — `frigate-hermes.nix` uses
   `http://shikisha:8123/…` (HA) — this is a **different service** (Home Assistant,
   not ntfy) and out of scope, but note it so we don't confuse it with ntfy.

---

## PART 4 — Delivery / Git Workflow (no commits made by this task)

Per `docs/references/agent-github-access.md`, `main` is protected by a branch
ruleset: `sprjr-bot` cannot push to `main` or merge. The rule set applies:

1. Create a feature branch from `main`.
2. Make the code edits (Step 1–2, 4).
3. Human re-encrypts sops secrets (Step 3) — agent cannot (no plaintext values).
4. `git push -u origin <branch>` as `sprjr-bot`.
5. Open a PR; request **human (`sprjr`) merge** (1 approval required, `sprjr`
   is the sole bypass).
6. Comin deploys on merge; manually rebuild `trixos`.

**This task did NOT create, modify, or commit any repository files.**

---

## Checklist Before Declaring "Done"

- [ ] New `nixos/modules/system/ntfy-host.nix` added to every host that imports
      `ip_check.nix` / `docker-healthcheck-restart.nix` (or modules remain
      orphaned/stale per Patrick's decision).
- [ ] Both hardcoded URLs replaced with `${config.ntfy.alertUrl}` (or the
      orphaned modules marked stale in-file per Patrick's decision).
- [ ] `monitoring/ntfy/{comin-url, grafana-alerts-url, frigate-events-url}`
      re-encrypted with the new host (human).
- [ ] `flake.nix` imports updated (ntfy-host + any resurrected script module).
- [ ] `nix flake check` / dry-build per affected host passes.
- [ ] PR to `main`, human merge, comin deploy + manual `trixos` rebuild.
- [ ] Out-of-repo ntfy consumers updated to new host.
