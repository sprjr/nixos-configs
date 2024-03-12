This stores my NixOS configs

## Usage

### NixOS

Assuming you want to build and switch to the `trixos` configuration:

```
nixos-rebuild switch --flake github:sprjr/nixos-configs#trixos
```

### Other Linux distributions

Assuming flakes are enabled:

```
nix run "github:sprjr/nixos-configs#homeConfigurations.patrick.activationPackage"
```
