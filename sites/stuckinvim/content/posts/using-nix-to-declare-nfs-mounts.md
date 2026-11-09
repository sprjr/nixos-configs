+++
title = "Using Nix to Declare NFS Mounts"
date = 2026-11-08

[taxonomies]
topic = ["technical"]
tags = ["nix", "nixos", "nfs", "network", "media", "disks"]
+++

Declaring network shares in Nix is much easier and more reliable than doing it by hand. Below is a single share from my homelab, followed by the module I now use to declare each share once and enable it per host.

## A single share

I declare each share hosted on my unRAID box (`dauntless`) individually, so I can add them to my various hosts in a modular way that resembles the principle of least privilege.

```nix
{ config, pkgs, ... }:

{
  # dauntless resolves over VPN DNS, which is not up during early boot; retry on access.
  fileSystems."/mnt/unraid/Media" = {
    device = "dauntless:/mnt/user/Media";
    fsType = "nfs";
    options = [
      "nofail"
      "retry=0"
      "noatime"
      "x-systemd.automount"
      "x-systemd.mount-timeout=15s"
      "x-systemd.after=tailscaled.service"
      "x-systemd.after=netbird-default.service"
    ];
  };
  boot.supportedFilesystems = [ "nfs" ];
}
```

The VPN ordering matters because dauntless resolves over NetBird DNS, which is not up during early boot. `x-systemd.automount` means the mount is not attempted at boot at all: the path stays a trigger until something touches it, by which point the tunnel is normally established. The two `x-systemd.after=` lines do not pull the VPN in.

Two options do the actual work when the VPN is not up:

- `retry=0` -- `mount.nfs` retries a failed foreground mount for two minutes by default, and each retry can itself take minutes over TCP. Zero means give up after the first attempt.
- `x-systemd.mount-timeout=15s` -- establishes a cap for how long the generated mount unit waits for the mount command before killing it.

Without both, a dead tunnel can block a shell on first access for several minutes. The full list of NFS-specific options lives in `mount.nfs(8)` and `nfs(5)`; for the generic ones I've also used [Arch Linux's documentation](https://man.archlinux.org/man/mount.8#Generic_Mount_Options).

## Verifying an automount

`df -h` and `duf` are the tools I reach for, but they read the mount table, and with automount what is there is the autofs stub rather than the share. To verify the declaration (replacing my mount with yours):

```
systemctl status mnt-unraid-Media.automount
ls /mnt/unraid/Media
findmnt /mnt/unraid/Media
```

The first shows the trigger is armed, the second triggers the mount, the third shows whether or not it landed.

## Many shares

The issue I ended up bumping into is that one `fileSystems` block per share works until it does not. As of writing this, I have six of them. This means six copies of the same option list. While it wasn't severe, I did start to see them drift: one share had `timeo` and `sync` because it holds git repositories, the others had neither, and nothing in the host file said which was deliberate. Besides that, fewer file imports that are accomplishing functionally the same thing throughout my config feels cleaner.

The replacement is an option module that takes a list per host. The share name, mountpoint and device are derived; only the differences are declared.

```nix
homelab.nfs-shares.shares = [
  { share = "Docker"; }
  { share = "Gitea"; extraOptions = [ "sync" ]; }
  { share = "Media"; workloadClass = "read-mostly"; }
  { share = "Other"; }
  { share = "Nextcloud/data"; mountPoint = "/var/lib/nextcloud/data"; }
];
```

A share that is not in the list generates no mount unit and no automount unit at all -- the path does not exist on that host. Nothing is shared implicitly.

The module itself is small, but offers valuable mapping:

```nix
fileSystems = listToAttrs (map (share:
  nameValuePair share.mountPoint {
    device = "dauntless:/mnt/user/${share.share}";
    fsType = "nfs";
    options = unique (commonOptions ++ policies.${share.workloadClass} ++ share.extraOptions);
  }
) cfg.shares);
```

`commonOptions` carries the automount, the VPN ordering, `retry=0` and `x-systemd.mount-timeout`, so every share inherits them. The rest depends on what the share is for:

- `write-critical` (the default) -- `hard`, `timeo=600`, `retrans=2`, `actimeo=1`.
- `read-mostly` -- `softerr`, `timeo=10`, `retrans=2`, `actimeo=5`, which returns `ETIMEDOUT` after the retransmissions are exhausted.

The split exists because a soft or `softerr` mount can return an error for a write the server already committed. That is fine for a media library this host only reads, but totally unacceptable for a git repository or Nextcloud's data directory. A share only qualifies for read-mostly if nothing on that host writes to it.

One thing that can still trip up successful mounting: hard mounts still block indefinitely if the link drops after the mount is established. No mount option gives both write integrity and fail-fast writes, so these timeouts are stuck addressing the attempt, but can't address anything around maintaining the mount.

Per-host lists are least privilege at the mount layer, but this doesn't address anything on the host serving the share. If the export is visible to your whole VPN subnet, any host on it can still mount the share. If you care, you'd need to set up restrictions on the host itself preventing unwanted access -- either through auth or network access.
