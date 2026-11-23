# ags-panels

GTK4 [AGS](https://github.com/aylur/ags) layer-shell panels for Wayland compositors, packaged as a
home-manager module. One AGS instance holds four panels that share a click-outside overlay; only one
is open at a time.

| Panel | Toggle command | Needs on PATH |
|---|---|---|
| Control center (network, audio, brightness, bluetooth, power profile, battery, media) | `control-center-toggle` | `nmcli`, `hyprlock` (lock button), `swaync-client` or `hokum` |
| Hardware monitor | `hw-monitor-toggle` | `hwstat` |
| Keybind cheat sheet | `keybinds-toggle` | none |
| Phone (KDE Connect) | `phone-panel-toggle` | KDE Connect daemon, `kdeconnect-cli`; `kdeconnect-status` is provided |

## Usage

```nix
# flake.nix
inputs.ags-panels.url = "github:sprjr/nixos-configs?dir=flakes/ags-panels";

# home-manager
imports = [ inputs.ags-panels.homeManagerModules.default ];

programs.agsPanels = {
  enable = true;
  panels.phone.enable = true;
  phone.bindHint = "Super B";
};
services.kdeconnect.enable = true;
```

`homeManagerModules.default` already imports `ags.homeManagerModules.default`. If your config imports
that module itself, import `(import "${inputs.ags-panels}/module.nix" { ags = inputs.ags; })` instead
so it isn't declared twice.

The module only installs the toggle commands; bind them in your compositor. On Hyprland, blur and
slide-in layer rules are added automatically (`hyprland.layerRules`).

## Options (`programs.agsPanels.*`)

| Option | Default | Purpose |
|---|---|---|
| `enable` | `false` | Enable the module |
| `systemdTarget` | `graphical-session.target` | Target that starts the `ags` user service |
| `colors.<token>` | stylix palette, else Catppuccin Mocha | `bg bg-alt bg-hover fg fg-dim accent green yellow red orange cyan purple border` |
| `laptop` | `false` | Exposes `--is-laptop` to CSS |
| `panels.{controlCenter,hwMonitor,keybinds}.enable` | `true` | Per-panel switches |
| `panels.phone.enable` | `false` | Phone panel + `kdeconnect-status` |
| `keybinds` | `[]` | `[{ title; icon; binds = [{ keys; desc; }]; }]` for the cheat sheet |
| `features.comin` | `false` | Comin section; needs `comin-state`, `comin-fleet` |
| `features.ollamaUsage` | `false` | Ollama Cloud usage section; needs `ollama-usage` |
| `features.notifications` | `swaync` | `swaync` or `hokum` for the do-not-disturb button |
| `phone.bindHint` | `""` | Key combo shown in the waybar tooltip |
| `hyprland.layerRules` | Hyprland enabled | Hyprland layer rules for the panels |

## Waybar phone module

```nix
"custom/kdeconnect" = {
  exec = "kdeconnect-status --waybar";
  return-type = "json";
  interval = 30;
  on-click = "phone-panel-toggle";
};
```

CSS classes: `charging`, `normal`, `warning` (<=30%), `critical` (<=15%), `unknown`, `offline`. While
charging, the glyph gains a lightning bolt (a Nerd Font is required).

## Ring

There is no known remote stop for KDE Connect's Find My Phone. The phone rings until it is touched: tap
the "Find my phone" screen or notification on the phone.
