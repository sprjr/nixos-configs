+++
title = "Recovering from a bad NixOS rollback"
date = 2026-10-15
[taxonomies]
topic = ["technical"]
tags = ["nix", "homelab"]
+++

Sometimes the previous generation is not the one you want.

## List available generations

```bash
nixos-rebuild list-generations
```

Pick the generation number you trust, then switch to it.

## Switch to a specific generation

```bash
sudo nixos-rebuild switch --generation 42
```

## A table of common rescue paths

| Problem           | Quick path                                  |
|-------------------|---------------------------------------------|
| Bad kernel        | Boot an older generation from the bootloader|
| Broken service    | `systemctl stop unit` then rollback           |
| Lost secrets      | Restore from SOPS backups before activation   |

## Remember

> Rollbacks are only easy if you keep generations.

Set a reasonable `configurationLimit` on `boot.loader.systemd-boot` or GRUB so you do not erase your escape hatch.
