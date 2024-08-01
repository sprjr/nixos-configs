This stores my NixOS configs

## Usage

### NixOS

Assuming you want to build and switch to the `trixos` configuration:

```
nixos-rebuild switch --flake github:sprjr/nixos-configs#trixos
```

### MacOS:

```
nix run "github:LNL7/nix-darwin#packages.aarch64-darwin.darwin-rebuild" -- switch --flake github:sprjr/nixos-configs#seair
```
Note:
You may need to add the flags `--extra-experimental-features nix-command --extra-experimental-features flakes` before the `--`, depending on your setup.

### Other Linux distributions

Assuming flakes are enabled:

```
nix run "github:sprjr/nixos-configs#homeConfigurations.patrick.activationPackage"
```
