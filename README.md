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

Secrets are encrypted with sops (`sops-nix/sops.yaml`). Decryption requires the age key at `/home/patrick/.config/sops/age/keys.txt`, which is deliberately not tracked.

On a fresh install the key is absent, so no secrets are decrypted on first boot and `sops-secrets-rendered` fails after 120 s. Provide it at deploy time:

```
nix run github:nix-community/nixos-anywhere -- --flake .#<host> \
  --target-host root@<host-ip> \
  --extra-files ./extra-files
```

with `extra-files/home/patrick/.config/sops/age/keys.txt` in place. `--extra-files` preserves file modes, so restrict it first:

```
chmod 600 extra-files/home/patrick/.config/sops/age/keys.txt
```

Files are copied root-owned, which is sufficient: `setupSecrets` runs as root at activation, so the key does not need to be owned by `patrick`.

To keep the key out of the deploy artifacts entirely, omit it from `--extra-files` and copy it onto the target after installation.
