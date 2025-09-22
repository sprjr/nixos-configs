This stores my NixOS configs

## Usage

### NixOS

(Available configurations at this time include):

#### NixOS
```trixos```
```seanix```
```seanvy```
```shikisha```
```prometheus```
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
