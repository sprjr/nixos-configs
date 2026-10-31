# Per-user NetBird identity on a shared NixOS device

## Recommendation (TL;DR)

Use a **separate NetBird client instance per human user on voyager**, running as a
systemd `--user` service in each person's login session, with a per-user
`NB_STATE_DIR` under `$HOME/.local/share/netbird` and the daemon control socket
under `$XDG_RUNTIME_DIR/netbird/sock`. Put every instance into **userspace
(netstack) mode** by default (`NB_USE_NETSTACK_MODE=true`) so the instances do
not fight over a single TUN device or the shared `netbird` routing table.

Each user must enroll with **interactive SSO login against the embedded Dex IdP**
(not a reusable setup key). A setup key enrolls a *peer*; it does **not**
create a NetBird *user* identity or attach a peer to a user. Only a user login
causes NetBird to record `UserID` on the peer, which makes per-user groups and
policies meaningful. The NixOS module therefore only provisions the daemon,
state directory, and socket path; the user (or a one-shot helper) performs the
interactive login once.

This model gives voyager multiple peers (e.g. `voyager-patrick`,
`voyager-whale`, `voyager-seagull`) that the NetBird admin can drop into
different user groups and write normal source→destination policies against.

## Evidence and upstream behaviour

### 1. nixpkgs `services.netbird.clients.<name>` supports multiple daemons, not truly isolated kernel routing

The nixpkgs NetBird module instantiates one systemd service per attribute in
`services.netbird.clients`.

| Item | Per-client value | Source |
|------|------------------|--------|
| systemd service | `netbird-<name>.service` or `netbird.service` for `name == "netbird"` | `nixos/modules/services/networking/netbird.nix`, `suffixedName` default |
| config path | `${client.dir.state}/config.json`, default `/var/lib/netbird-<name>/config.json` | `dir.state` option, `NB_CONFIG` env |
| state dir | `/var/lib/netbird-<name>` via `StateDirectory` | `dir.state` option |
| runtime/socket | `/var/run/netbird-<name>/sock` via `RuntimeDirectory` | `dir.runtime` option, `NB_DAEMON_ADDR` env |
| interface | default `nb-<name>` (15-char limit enforced) | `interface` option |
| WireGuard port | per-client `client.port`, default `51820` | `port` option, `NB_WIREGUARD_PORT` env |

The module's own caveats list the exact problem:

> multiple daemons will interfere with each other's DNS resolution of
> `netbird.cloud`, but should remain fully operational otherwise.

That "otherwise" is optimistic for the kernel/TUN path. The module's caveats do
not mention routing-table collision, but upstream source shows it is real.

### 2. Kernel/TUN mode with two clients on one host: routing collision, not viable for per-user separation

NetBird on Linux uses a **single, hard-coded routing table** for kernel mode:

```go
const (
    NetbirdVPNTableID   = 0x1BD0   // 7120 decimal
    NetbirdVPNTableName = "netbird"
)
```

Source: `client/internal/routemanager/systemops/systemops_linux.go` in v0.82.0
(via `pkg.go.dev` and raw source browse).

It also installs host-global `ip rule` entries at fixed priorities 105 and 110,
and `DefaultManager.Init()` calls `CleanupRouting()` unconditionally on every
start. That cleanup flushes the whole shared `netbird` table and removes the
shared rules. A second instance therefore wipes routes belonging to the first,
and because NetBird's route ref-counter only runs `AddFunc` on the 0→1
transition, the first instance never reinstalls them until it restarts.

A GitHub issue filed by the nixpkgs module author confirms this is still
unfixed at v0.78.2 and describes the required fix:

> option 1 from the original post needs the rule priority base to be
> configurable too, and `CleanupRouting` scoped to the instance's own table and
> rules, not just the table id and the name.

Source: `netbirdio/netbird#2023`, comment dated Sep 25 2026.

Policy routing by `uid`/`fwmark` would require code changes; there is no
upstream support for "route this user's packets into a separate NetBird table".
`NB_FWMARK_BASE` exists, but it only moves NetBird's own mark range; it does
not make the table or rules per-user. A single default-route peer would win the
global routing table and break other users.

**Verdict:** kernel/TUN per-user instances on the same host are a **dead end**
without upstream changes.

### 3. Userspace (netstack) mode: what it actually does

Setting `NB_USE_NETSTACK_MODE=true` makes the client run WireGuard on top of
gVisor netstack instead of creating a TUN device.

```go
const EnvUseNetstackMode = "NB_USE_NETSTACK_MODE"
// IsEnabled todo: move these function to cmd layer
func IsEnabled() bool {
    return os.Getenv(EnvUseNetstackMode) == "true"
}
```

Source: `client/iface/netstack/env.go` in v0.82.0.

By default netstack mode starts a **local, unauthenticated SOCKS5 proxy** bound
to `127.0.0.1:1080` (overridable with `NB_SOCKS5_LISTENER_ADDRESS` and
`NB_SOCKS5_LISTENER_PORT`):

> Run WireGuard on top of a userspace TCP/IP stack (gVisor netstack) instead of
> a TUN device. Required for environments without TUN support (e.g.
> unprivileged containers).

> The proxy is unauthenticated and meant for local applications only, so it
> listens on loopback.

Source: `docs.netbird.io/client/environment-variables`, "WireGuard and
interface" table.

The same docs note limitations that matter for a desktop:

- no system-wide DNS takeover (the client does not rewrite `/etc/resolv.conf`);
- applications must be configured to use the SOCKS5 proxy (or run inside a
  wrapper such as `proxychains-ng`);
- a netstack peer cannot act as a routing peer or exit node;
- TCP/UDP/ping work, but transparent capture of all traffic does not.

A user-scoped instance is achieved by setting `NB_STATE_DIR` to a per-user
location. NetBird's profile manager already stores additional profiles under a
per-user subdirectory when it knows the username:

```go
func (a *ActiveProfileState) FilePath() (string, error) {
    ...
    configDir, err := getConfigDirForUser(a.Username)
    ...
    return filepath.Join(configDir, a.ID.String()+".json"), nil
}
```

Source: `client/internal/profilemanager/service.go` in v0.82.0.

The default Linux state directory is `/var/lib/netbird/`, but `NB_STATE_DIR`
overrides it. For a `--user` systemd unit, `$HOME/.local/share/netbird` is a
natural per-user state dir and matches the XDG base dir convention.

### 4. Identity model: setup keys enroll peers, not users

NetBird's access-control docs are explicit:

> It's important to note that NetBird doesn't technically differentiate between
> "user groups" and "peer groups" in the interface — all groups appear together
> in the Groups page.

The practical distinction is how membership is assigned:

- **User groups** are assigned to user accounts and inherited by any peer that
  user logs into (via SSO/IdP, or manually on the user account).
- **Peer groups** are assigned directly to infrastructure peers, usually through
  setup-key auto-assignment.

Source: `docs.netbird.io/manage/access-control`, "User Groups vs. Peer Groups".

At the management API level, a peer is registered with **either** a `setupKey`
**or** a `userID`:

```go
type PeerLogin struct {
    WireGuardPubKey string
    SSHKey          string
    Meta            nbpeer.PeerSystemMeta
    UserID          string  // empty when SetupKey is used
    SetupKey        string  // empty when UserID is used
    ConnectionIP    net.IP
    ExtraDNSLabels  []string
}
```

Source: `management/server/types/peer.go` (v0.26.4 shape, still present in
v0.82.0 management gRPC). Also `management/internals/shared/grpc/server.go`
calls `accountManager.LoginPeer` with `UserID` from the JWT and `SetupKey` from
the request.

`AddPeer` fails when both are empty:

```go
if setupKey == "" && userID == "" {
    return nil, nil, status.Errorf(status.Unauthenticated,
        "no peer auth method provided, please use a setup key or interactive SSO login")
}
```

Source: `management/server/peer.go`.

Therefore:

- **(a) separate setup keys per user** creates separate *peers* but each peer
  has an empty `UserID`. It is not tied to a NetBird user, so user-group-based
  policies do not apply automatically. The admin can still assign each peer to
  a group manually, but that is peer-level access, not user-level identity.
- **(b) separate Dex accounts per user with interactive login** creates peers
  with non-empty `UserID` that inherit the user's groups. This is the only
  model that gives NetBird's policy engine a user identity to evaluate.
- **(c) something else** such as profiles or multiple client instances alone
  does not change NetBird's view of the peer; the authentication method at
  enrollment does.

A NetBird maintainer confirmed this in a discussion:

> Give each Windows user their own profile and log it in with SSO, so each
> profile is a separate peer owned by that user and your per-user policies
> apply.

Source: `netbirdio/netbird#6520`.

### 5. Access control objects for the chosen model

With per-user SSO peers, the admin creates the same NetBird objects used for any
human user:

- **Users** in Team → Users (local Dex accounts or IdP accounts). Each voyager
  human gets one.
- **User groups** such as `voyager-users`, `voyager-admins`,
  `voyager-guests`. Groups are assigned to *users*, not peers.
- **Peer groups** for resources the users need to reach, e.g.
  `homelab-servers`, `ds9-admin`, `prometheus`, `nix-store`.
- **Network resources** (optional) for subnets behind routing peers, e.g.
  `home-lan-10.0.0.0/24`.
- **Policies** with direction user-group → peer-group or user-group → network
  resource, specifying protocol and port. For example:
  - `voyager-admins` → `ds9-admin`, TCP 22,443.
  - `voyager-users` → `homelab-servers`, TCP 443.
  - `voyager-guests` → `internet-exit` (if an exit node is offered).
- Remove or restrict the **Default policy** that allows `All` → `All`, because
  it defeats per-user segmentation.

Each user's peer on voyager inherits its user's groups automatically, so the
same person gets the same access no matter which physical machine they use, and
their voyager peer can be denied without affecting a different user's voyager
peer.

## Trade-offs

| Approach | Pros | Cons |
|----------|------|------|
| **Userspace per-user (recommended)** | No TUN/routing-table fights; each user a distinct peer with real user identity; no root after login | Apps must use SOCKS5 proxy; no transparent DNS capture; no routing-peer/exit-node support on the shared device |
| **Kernel/TUN per-user** | Transparent, full NetBird feature set | Hard-coded shared `netbird` routing table makes multiple instances mutually destructive; dead end without upstream fixes |
| **Single system peer + setup key (status quo)** | Simple, works today on all hosts | All voyager users share one identity and one access policy; guest account inherits owner's reach |
| **Interactive login only, no setup key** | Correct user attribution | Requires each user to complete browser/device-auth flow; headless or auto-login scenarios need manual setup |

## What breaks for existing single-identity hosts

Nothing changes on hosts that keep `services.netbird.clients.default`. The
per-user module is a new, additive `homelab.netbird.perUser.enable` option
scoped to voyager only.

If voyager is migrated from the existing `default` setup-key peer:

1. The old system peer remains enrolled but should be removed from groups and
   policies, then deleted from the NetBird dashboard after users are set up.
2. DNS for `*.netbird.cloud` stops being system-wide. Users in netstack mode
   resolve NetBird names only through the proxy-aware application or by adding
   the per-user SOCKS5 DNS forwarder in their own resolver config.
3. Scripts and services that relied on the `netbird0` interface on voyager
   must either run as a specific user with the proxy set, or move to a
   dedicated system peer on another host.

## Migration path

1. Merge the NixOS sketch behind `homelab.netbird.perUser.enable = false`.
2. Create local Dex users in NetBird for patrick, whale, seagull.
3. Assign them to user groups reflecting desired access.
4. Enable the option on voyager and let each user log in once with
   `netbird up --management-url https://nb.rawliyosh.com`.
5. Verify each user's peer appears in the dashboard with the expected groups.
6. Write/replace policies, then delete the old `voyager` system peer.

## NixOS sketch

A minimal, disabled-by-default module. It does **not** touch the existing
`services.netbird.clients.default` path used by other hosts; voyager would
explicitly set `services.netbird.clients.default.enable = false` or simply not
import the existing client module when per-user mode is enabled.

```nix
# nixos/modules/homelab/netbird-per-user.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.homelab.netbird.perUser;

  # Per-user daemon wrapper with isolated state/socket/proxy port.
  mkUserService = user: nameValuePair "netbird-${user}" {
    Unit.Description = "NetBird client for ${user}";
    Install.WantedBy = [ "default.target" ];

    Service = {
      Type = "simple";
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "netbird-${user}-run" ''
        export NB_STATE_DIR="/home/${user}/.local/share/netbird"
        export NB_CONFIG="$NB_STATE_DIR/config.json"
        export NB_DAEMON_ADDR="unix://$XDG_RUNTIME_DIR/netbird/sock"
        export NB_USE_NETSTACK_MODE="true"
        export NB_SOCKS5_LISTENER_PORT="${toString (1080 + cfg.users.${user}.proxyPortOffset)}"
        export NB_LOG_FILE="console"
        export NB_LOG_LEVEL="info"
        export NB_WIREGUARD_PORT="${toString cfg.users.${user}.wgPort}"
        exec ${lib.getExe config.services.netbird.package} service run
      '');
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
in
{
  options.homelab.netbird.perUser = {
    enable = lib.mkEnableOption "per-user NetBird clients on this host";

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          proxyPortOffset = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "Offset added to base SOCKS5 port 1080 for this user.";
          };
          wgPort = lib.mkOption {
            type = lib.types.port;
            default = 51820;
            description = "WireGuard listen port for this user's instance.";
          };
        };
      });
      default = { };
      example = lib.literalExpression ''
        {
          patrick = { proxyPortOffset = 0; wgPort = 51820; };
          whale   = { proxyPortOffset = 1; wgPort = 51821; };
          seagull = { proxyPortOffset = 2; wgPort = 51822; };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Each user's instance must keep running after logout, otherwise a user
    # who SSHs in and out loses NetBird mid-session. Enable lingering for
    # every configured user.
    services.logind.lingerUsers = lib.attrNames cfg.users;

    # The firewall only needs the per-user WireGuard ports opened. The SOCKS5
    # proxy binds loopback and is never exposed.
    networking.firewall.allowedUDPPorts = lib.mapAttrsToList (_: u: u.wgPort) cfg.users;

    systemd.user.services = lib.mapAttrs' mkUserService cfg.users;

    # sops-nix secrets for interactive login tokens are not used here; login is
    # interactive via Dex. If a headless enrollment helper is added later,
    # name secrets sops.secrets."netbird/per-user/<user>/setup-key" or
    # "netbird/per-user/<user>/oauth-refresh".
  };
}
```

Integration in `flake.nix` for voyager:

```nix
[
  ./nixos/modules/homelab/netbird-per-user.nix
  {
    homelab.netbird.perUser.enable = false; # disabled by default
    homelab.netbird.perUser.users = {
      patrick.proxyPortOffset = 0;
      whale.proxyPortOffset   = 1;
      seagull.proxyPortOffset = 2;
    };
    # voyager no longer uses the single system peer
    services.netbird.clients.default.enable = lib.mkForce false;
  }
]
```

## Open questions

1. Does the NetBird UI/desktop tray on voyager respect a non-default
   `--daemon-addr`? The nixpkgs wrapper passes it for system instances; the
   per-user tray wrapper would need the same treatment.
2. Should the per-user module also generate `proxychains-ng` / desktop entry
   wrappers so graphical apps can reach NetBird resources transparently-ish?
3. Is there a desire to keep a fallback *system* peer on voyager for system
   services, or should all traffic from voyager be user-scoped?
4. Are there resources currently reached through the voyager system peer that
   cannot tolerate SOCKS5 proxying (e.g. game launchers, Kubernetes contexts)?
5. How will users perform the interactive login on a headless or Wayland
   session? `netbird up` prints a URL, but a browser must be available.
6. Should sops-nix store a per-user *refresh token* after first login so the
   daemon can reconnect automatically without re-authenticating? NetBird
   supports long-lived device authorization, but the exact file format and
   refresh semantics in v0.82.0 need verification.

## References

- NixOS NetBird module: `https://raw.githubusercontent.com/NixOS/nixpkgs/master/nixos/modules/services/networking/netbird.nix`
- NetBird v0.82.0 profile manager (`client/internal/profilemanager/service.go`): `https://raw.githubusercontent.com/netbirdio/netbird/v0.82.0/client/internal/profilemanager/service.go`
- NetBird v0.82.0 netstack env (`client/iface/netstack/env.go`): `https://raw.githubusercontent.com/netbirdio/netbird/v0.82.0/client/iface/netstack/env.go`
- NetBird client environment variables docs: `https://docs.netbird.io/client/environment-variables`
- NetBird access-control docs: `https://docs.netbird.io/manage/access-control`
- NetBird local user management docs: `https://docs.netbird.io/selfhosted/identity-providers/local`
- NetBird management peer login types (`management/server/types/peer.go`): `https://github.com/netbirdio/netbird/blob/main/management/server/types/peer.go`
- NetBird management `AddPeer`/`LoginPeer` (`management/server/peer.go`): `https://github.com/netbirdio/netbird/blob/v0.26.4/management/server/peer.go`
- NetBird multi-instance routing collision issue: `https://github.com/netbirdio/netbird/issues/2023`
- NetBird per-Windows-user profile discussion: `https://github.com/netbirdio/netbird/discussions/6520`
- NetBird systemd template unit (`release_files/systemd/netbird@.service`): `https://github.com/netbirdio/netbird/blob/main/release_files/systemd/netbird%40.service`
