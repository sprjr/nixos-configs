# nixos-configs — Codebase Index

Navigation aid for agents. Read this before scanning the directory tree.
`flake.nix` is authoritative for exact module lists; this index is for fast lookup.
Last updated: 2026-06-22.

---

## Common task quick-reference

| Task | Files to touch |
|------|---------------|
| Add a package for all hosts | `home/modules/general/packages.nix` |
| Add a package to one host | `nixos/<hostname>.nix` (system pkgs) or relevant home profile |
| Add a new NixOS module | Create `nixos/modules/<category>/<name>.nix`, add path to host in `flake.nix` |
| Add a new home-manager module | Create `home/modules/<category>/<name>.nix`, import in `home/<profile>-home.nix` |
| Change shell/prompt | `nixos/modules/shell/starship.nix` |
| Change terminal (Ghostty) | `home/modules/tools/ghostty.nix` |
| Change terminal (Alacritty) | `home/modules/tools/alacritty.nix` |
| Change Zellij layout/config | `home/modules/user-space/zellij/` |
| Change Helix editor | `home/modules/tools/helix/config.nix`, `languages.nix` |
| Change Neovim | `home/modules/tools/neovim.nix` |
| Change theming (base16/wallpaper) | `home/modules/user-space/stylix/stylix.nix` |
| Change GTK theme | `home/modules/user-space/themes/gtk.nix` |
| Change Waybar | `home/modules/user-space/waybar/waybar.nix` |
| Change Hyprland config | `home/modules/user-space/hyprland/` |
| Change COSMIC DE config | `home/modules/user-space/cosmic/cosmic.nix` |
| Add/edit a secret | Edit `sops-nix/sops.yaml` via `sops` CLI, declare in relevant module |
| Change patrick user / home-manager wiring | `nixos/modules/user/patrick.nix` |
| Change comin remote URL or polling | `nixos/modules/system/comin.nix` |
| Add a new NixOS host | See CLAUDE.md "Adding a new NixOS host" |

---

## Host → module matrix

Derived from `flake.nix`. For exact imports, read the relevant `nixosConfigurations` block.

### `nx-01` (x86_64-linux — COSMIC desktop, office work)
- `nixos/nx-01.nix`
- `nixos/modules/system/comin.nix`, `comin-notify.nix`, `sops.nix`
- `nixos/modules/network/wifi.nix`
- `nixos/modules/user/patrick.nix`
- `nixos/modules/homelab/syncthing-client-preset.nix`
- `nixos/modules/desktop/cosmic.nix`

### `seanix` (x86_64-linux — gaming/workstation, Nvidia, ollama)
- `nixos/seanix.nix`
- `nixos/modules/system/comin.nix`, `comin-notify.nix`, `sops.nix`, `nvidia-seanix.nix`, `udev-scrcpy.nix`
- `nixos/modules/network/wifi.nix`
- `nixos/modules/user/patrick-desktop.nix`
- `nixos/modules/homelab/syncthing-client-preset.nix`
- `nixos/modules/homelab/ollama-nvidia.nix`
- `nixos/modules/gaming/sunshine.nix`, `cachyos-gaming.nix`

### `shikisha` (x86_64-linux — homelab server)
- `nixos/shikisha.nix`
- `nixos/modules/system/comin.nix`, `comin-notify.nix`, `sops.nix`
- `nixos/modules/homelab/syncthing-hub.nix`, `nextcloud.nix`, `mosquitto.nix`, `attic.nix`
- `nixos/modules/homelab/storage/garage.nix`, `garage-systemd-service.nix`
- `nixos/modules/virtualisation/k3s-server.nix`, `longhorn-configuration.nix`
- `nixos/modules/disks/` (multiple unraid NFS mounts)
- `nixos/hosts/shikisha/cron/` (docker-findmy-restart, authentik-backup, podcast-downloader)

### `prometheus` (x86_64-linux — productivity workstation)
- `nixos/prometheus.nix`
- `nixos/modules/system/comin.nix`, `comin-notify.nix`, `sops.nix`
- `nixos/modules/network/wifi.nix`
- `nixos/modules/user/patrick.nix`
- `nixos/modules/homelab/syncthing-client-preset.nix`
- `nixos/modules/monitoring/node-exporter.nix`, `zabbix-agent.nix`

### `voyager` (x86_64-linux — KDE Glass desktop, fprintd)
- `nixos/voyager.nix`
- `nixos/modules/system/comin.nix`, `comin-notify.nix`, `sops.nix`, `fprintd.nix`
- `nixos/modules/network/wifi.nix`
- `nixos/modules/user/patrick.nix`
- `nixos/modules/homelab/syncthing-client-preset.nix`
- `nixos/modules/desktop/kde-glass.nix`

### `trixos` (x86_64-linux — gaming, Nvidia prime, no comin)
- `nixos/trixos.nix`
- `nixos/modules/system/sops.nix` (no comin — manual rebuild only)
- `nixos/modules/homelab/syncthing-client-preset.nix`
- `nixos/modules/nvidia.nix`
- `nixos/modules/gaming/windows-vm.nix`, `cachyos-gaming.nix`
- Hardware config: `/etc/nixos/hardware-configuration.nix` (local on machine, not in repo)

### `seair` (aarch64-darwin — M2 MacBook Air)
- `darwin/hosts/seair.nix`
- `darwin/modules/sops.nix`, `darwin/modules/sketchybar.nix`
- `home/darwin-home.nix`

### `defiant` (aarch64-darwin — M4 MacBook Air)
- `darwin/hosts/defiant.nix`
- `darwin/modules/sops.nix`, `darwin/modules/sketchybar.nix`
- `home/darwin-home.nix`

---

## Home-manager profile → module matrix

### `home/laptop-home.nix` (default for most NixOS hosts via `patrick.nix`)
- `home/modules/general/packages.nix`
- `home/modules/tools/ghostty.nix`, `helix/`, `neovim.nix`, `claude.nix`
- `home/modules/user-space/bat.nix`, `btop.nix`, `shell.nix`, `colors.nix`
- `home/modules/user-space/zellij/` (config, layout, themes)
- `home/modules/user-space/stylix/stylix.nix`

### `home/desktop-home.nix` (heavier package set)
- Extends laptop-home with additional desktop packages
- `home/modules/user-space/waybar/waybar.nix`
- `home/modules/user-space/themes/gtk.nix`

### `home/hyprland-home.nix`
- `home/modules/user-space/hyprland/` (hyprland, hypridle, hyprlock, random_wallpaper)
- `home/modules/user-space/waybar/waybar.nix`

### `home/darwin-home.nix`
- `home/modules/tools/ghostty.nix`, `helix/`, `neovim.nix`
- `home/modules/user-space/zellij/zellij-layout-darwin.nix`
- `home/modules/user-space/bat.nix`, `btop.nix`, `shell.nix`

---

## NixOS module registry (`nixos/modules/`)

### `system/`
| File | Purpose |
|------|---------|
| `system/comin.nix` | Comin GitOps poller — reads hostName to select flake output |
| `system/comin-notify.nix` | Failure hook via ntfy.sh |
| `system/sops.nix` | SOPS age key + default sops.yaml path |
| `system/btrfs-config.nix` | Btrfs boot options with TPM + systemd initrd |
| `system/fprintd.nix` | Fingerprint reader (Goodix touch-on-display) |
| `system/nvidia-seanix.nix` | Nvidia driver with nvidia-patch overlay for seanix |
| `system/esp-tooling.nix` | ESP32 dev tools, USB-to-UART kernel modules + udev |
| `system/udev-scrcpy.nix` | Scrcpy Android screen mirroring udev rules |
| `system/attic-cache.nix` | Attic binary cache client (placeholder) |

### `network/`
| File | Purpose |
|------|---------|
| `network/wifi.nix` | NetworkManager WiFi with SOPS password secrets |
| `network/scripts/ip_check.nix` | Python IP monitor with ntfy notifications |

### `desktop/`
| File | Purpose |
|------|---------|
| `desktop/cosmic.nix` | COSMIC DE (System76) with Orca disabled |
| `desktop/kde-glass.nix` | KDE Plasma with glassOS custom theme |
| `desktop/gnome.nix` | GNOME with GDM |

### `gaming/`
| File | Purpose |
|------|---------|
| `gaming/cachyos-gaming.nix` | CachyOS kernel gaming optimizations |
| `gaming/sunshine.nix` | Sunshine game streaming server + firewall |
| `gaming/windows-vm.nix` | Windows gaming VM with GPU passthrough (AMD 5700 XT) |
| `gaming/looking-glass-client.nix` | Looking Glass low-latency VM display |

### `homelab/`
| File | Purpose |
|------|---------|
| `homelab/ollama-nvidia.nix` | Ollama LLM with Nvidia CUDA |
| `homelab/ollama-amd.nix` | Ollama LLM with AMD ROCm |
| `homelab/ollama-cpu.nix` | Ollama LLM CPU-only |
| `homelab/nextcloud.nix` | Nextcloud with MySQL + Unraid mount |
| `homelab/mosquitto.nix` | MQTT broker with ACL config |
| `homelab/attic.nix` | Attic binary cache server + SOPS secrets |
| `homelab/syncthing-hub.nix` | Syncthing hub controller |
| `homelab/syncthing-client.nix` | Syncthing client (vault path + folder options) |
| `homelab/syncthing-client-preset.nix` | Syncthing client preset (imports secrets + client) |
| `homelab/netbird-server.nix` | Netbird VPN server + UI |
| `homelab/certbot-mumble.nix` | Certbot + Mumble VoIP with SOPS secrets |
| `homelab/tangled-knot.nix` | Tangled Knot DNS recursive resolver |
| `homelab/storage/garage.nix` | Garage S3 object store with SOPS secrets |
| `homelab/storage/garage-systemd-service.nix` | Garage systemd unit definition |

### `monitoring/`
| File | Purpose |
|------|---------|
| `monitoring/node-exporter.nix` | Prometheus node exporter (systemd collector) |
| `monitoring/zabbix-agent.nix` | Zabbix agent with Tailscale network integration |
| `monitoring/graylog.nix` | Graylog log aggregation via OCI containers |

### `virtualisation/`
| File | Purpose |
|------|---------|
| `virtualisation/k3s-server.nix` | K3s Kubernetes server + VXLAN firewall |
| `virtualisation/k3s-node.nix` | K3s Kubernetes node |
| `virtualisation/longhorn-configuration.nix` | Longhorn persistent storage + iSCSI |
| `virtualisation/vm/windows.nix` | Windows VM with QEMU/KVM + virt-manager |
| `virtualisation/vm/nix-vm.nix` | Nested NixOS VM |
| `virtualisation/containers/gitea.nix` | Gitea Docker Compose config |
| `virtualisation/containers/home-assistant.nix` | Home Assistant container |
| `virtualisation/containers/syncthing.nix` | Syncthing container |
| `virtualisation/containers/windows.nix` | Windows Docker container systemd unit |

### `disks/`
| File | Purpose |
|------|---------|
| `disks/unraid-other.nix` | NFS mount: Unraid "Other" share |
| `disks/unraid-nextcloud.nix` | NFS mount: Unraid Nextcloud share |
| `disks/unraid-kubernetes.nix` | NFS mount: Unraid Kubernetes share |
| `disks/unraid-photos.nix` | NFS mount: Unraid Photos share |
| `disks/unraid-workstations.nix` | NFS mount: Unraid Workstations share |
| `disks/unraid-gitea.nix` | NFS mount: Unraid Gitea share |
| `disks/unraid-docker.nix` | NFS mount: Unraid Docker share |
| `disks/hetzner-box-cifs.nix` | CIFS mount: Hetzner storage box |
| `disks/macnnix-ns.nix` | CIFS mount: NetBird-routed Unraid backup |
| `disks/seanix-mount.nix` | EXT4 mount: Seanix media storage |

### `user/`
| File | Purpose |
|------|---------|
| `user/patrick.nix` | Creates patrick user + wires home-manager (laptop-home.nix) |
| `user/patrick-desktop.nix` | Desktop variant of patrick user config |
| `user/omarchy.nix` | Omarchy user with Nord theme |
| `user/btop.nix` | Btop with Nord theme (system-level) |
| `user/sops-ha-helper.nix` | Home Assistant token SOPS secret |

### `shell/`
| File | Purpose |
|------|---------|
| `shell/starship.nix` | Starship prompt with nerd font symbols |

### `backups/`
| File | Purpose |
|------|---------|
| `backups/rsnapshot.nix` | Rsnapshot backup with chown script |

### `scripts/`
| File | Purpose |
|------|---------|
| `scripts/docker-healthcheck-restart.nix` | Docker health monitor with auto-restart |

### `nvidia.nix` (top-level)
Generic Nvidia driver with 32-bit support. Use `system/nvidia-seanix.nix` for seanix-specific config.

---

## Home-manager module registry (`home/modules/`)

### `general/`
| File | Purpose |
|------|---------|
| `general/packages.nix` | Common packages for all home-manager users |

### `tools/`
| File | Purpose |
|------|---------|
| `tools/ghostty.nix` | Ghostty terminal — JetBrains Mono, Nord theme |
| `tools/alacritty.nix` | Alacritty terminal — Nord colors |
| `tools/neovim.nix` | Neovim with plugin ecosystem |
| `tools/claude.nix` | Claude Code agent config + permissions |
| `tools/opencode.nix` | VSCode remote dev config |
| `tools/cli-visualizer.nix` | CLI music visualizer — Nord palette |
| `tools/helix/config.nix` | Helix base config |
| `tools/helix/languages.nix` | Helix LSPs: bash-lsp, nixfmt, pyright, ruff |
| `tools/helix/theme-catppuccin-mocha.nix` | Catppuccin Mocha theme (placeholder) |

### `user-space/`
| File | Purpose |
|------|---------|
| `user-space/bat.nix` | Bat syntax highlighter — Nord theme |
| `user-space/btop.nix` | Btop — Nord theme, vim keybinds |
| `user-space/shell.nix` | Shell env vars (EDITOR, SHELL) |
| `user-space/colors.nix` | ANSI color vars for terminal scripts |
| `user-space/monitor-switch.nix` | Multi-monitor switching script |
| `user-space/cosmic/cosmic.nix` | COSMIC DE home-manager config |
| `user-space/zellij/zellij-config.nix` | Zellij — Nord theme config |
| `user-space/zellij/zellij-layout.nix` | Zellij layout (horizontal split) |
| `user-space/zellij/zellij-layout-darwin.nix` | Zellij layout for macOS (borderless) |
| `user-space/zellij/zellij-layout-desktop.nix` | Zellij desktop layout (nvtop/htop monitoring) |
| `user-space/zellij/themes.nix` | Zellij Nord theme |
| `user-space/hyprland/hyprland.nix` | Hyprland compositor + plugins + xwayland |
| `user-space/hyprland/hyprland-home.nix` | Hyprland home-manager module |
| `user-space/hyprland/hypridle.nix` | Hypridle idle daemon (lock/sleep) |
| `user-space/hyprland/hyprlock.nix` | Hyprlock screen locker — Nord colors |
| `user-space/hyprland/random_wallpaper.nix` | Systemd timer for random wallpaper |
| `user-space/waybar/waybar.nix` | Waybar panel — network/CPU monitoring |
| `user-space/stylix/stylix.nix` | Stylix — Nord base16 scheme + wallpaper |
| `user-space/themes/gtk.nix` | GTK theme — Nordic |

### `gaming/`
| File | Purpose |
|------|---------|
| `gaming/looking-glass-client.nix` | Looking Glass client home-manager config |

---

## Darwin module registry (`darwin/modules/`)

| File | Purpose |
|------|---------|
| `darwin/modules/sops.nix` | SOPS secrets for macOS with age keyfile |
| `darwin/modules/sketchybar.nix` | Sketchybar menu bar with space indicators |

---

## Host-specific files (`nixos/hosts/`)

| File | Purpose |
|------|---------|
| `hosts/shikisha/cron/docker-findmy-restart.nix` | Daily cron: restart FindMy Docker container |
| `hosts/shikisha/cron/authentik-backup.nix` | Weekly cron (Sun 22:00 UTC): Authentik backup |
| `hosts/shikisha/cron/podcast-downloader.nix` | Podcast downloader with Python + systemd |
