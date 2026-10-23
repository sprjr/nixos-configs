This stores my NixOS configs

> Note: AI-assisted changes are made to this repo in a reviewed, careful context.

## Usage

### NixOS

(Available configurations at this time include):

#### NixOS
```seanix```
```seanvy```
```shikisha```
The names vaguely have relation to their function, but just as well might not.

#### Darwin
```seair```

Assuming you want to switch to the ```seanix``` configuration:

```
nixos-rebuild switch --flake github:sprjr/nixos-configs#seanix
```

Note: I've realized that hardware-specific information is present in these system flakes, so it may need to be ran as `--impure` or with other flags as needed.

### MacOS:

```
nix run "github:LNL7/nix-darwin#packages.aarch64-darwin.darwin-rebuild" -- switch --flake github:sprjr/nixos-configs#seair
```
Note:
You may need to add the flags `--extra-experimental-features nix-command --extra-experimental-features flakes` before the `--`, depending on your setup, and it may be `--impure`.

### Other Linux distributions

Assuming flakes are enabled:

```
nix run "github:sprjr/nixos-configs#homeConfigurations.patrick.activationPackage"
```

### Secrets

Secrets are encrypted with sops (`sops-nix/sops.yaml`). System-level decryption uses the age key at `/var/lib/sops-nix/key.txt`, which is deliberately not tracked. Home-manager sops modules still read `/home/patrick/.config/sops/age/keys.txt`.

The system key must be readable before `/home` is mounted: initrd activation runs as root and home is not available at that point. `/var` is, so the key lives there, root-owned `0400`. Provide it at deploy time:

```
nix run github:nix-community/nixos-anywhere -- --flake .#<host> \
  --target-host root@<host-ip> \
  --extra-files ./extra-files
```

with `extra-files/var/lib/sops-nix/key.txt` in place. `--extra-files` preserves file modes, so restrict it first:

```
chmod 400 extra-files/var/lib/sops-nix/key.txt
```

If the key is absent, no secrets are decrypted, `sops-secrets-rendered` blocks `multi-user.target` for 120 s on every boot, and any session started before boot completes stalls 60 s waiting for `graphical.target`.

To keep the key out of the deploy artifacts entirely, omit it from `--extra-files` and copy it onto the target after installation.

Existing hosts that already carry the key at the home path need it copied to `/var/lib/sops-nix/key.txt` (root-owned `0400`) before the next boot with this module, or sops decryption fails there.
