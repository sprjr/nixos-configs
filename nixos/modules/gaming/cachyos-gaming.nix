{ config, pkgs, lib, nix-cachyos-kernel, ... }:

let
  pciLatencyScript = pkgs.writeShellScript "pci-latency" ''
    for dev in /sys/bus/pci/devices/*/latency_timer; do
      echo 20 > "$dev" 2>/dev/null || true
    done
    # Root bus: 0ms
    for dev in /sys/bus/pci/devices/0000:00:*/latency_timer; do
      echo 0 > "$dev" 2>/dev/null || true
    done
    # Sound devices: 80ms
    for dev in /sys/bus/pci/devices/*/class; do
      if [ "$(cat "$dev" 2>/dev/null)" = "0x040100" ]; then
        dir=$(dirname "$dev")
        echo 80 > "$dir/latency_timer" 2>/dev/null || true
      fi
    done
  '';
in {
  # CachyOS kernel overlay (pinned = stable + binary-cached)
  nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];

  # Binary caches for pre-built CachyOS kernels; avoids local compilation
  nix.settings = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  # CachyOS kernel with BORE/EEVDF scheduler; overrides nvidia-seanix.nix's mkDefault linux_zen
  boot.kernelPackages = pkgs.cachyosKernels."linuxPackages-cachyos-latest";

  boot.kernelParams = [
    "amd_pstate=active"
    "split_lock_detect=off"
    "nvidia.NVreg_UsePageAttributeTable=1"
    "nvidia.NVreg_InitializeSystemMemoryAllocations=0"
    "nvidia.NVreg_RegistryDwords=RMIntrLockingMode=1"
  ];

  boot.kernelModules = [ "bfq" ];
  # Watchdog causes boot delays on AMD B550/X570 boards
  boot.blacklistedKernelModules = [ "sp5100_tco" ];

  boot.kernel.sysctl = {
    "vm.swappiness"                    = 150;   # high is correct with ZRAM
    "vm.vfs_cache_pressure"            = 50;
    "vm.dirty_bytes"                   = 268435456;
    "vm.dirty_background_bytes"        = 67108864;
    "vm.dirty_writeback_centisecs"     = 1500;
    "vm.page-cluster"                  = 0;
    "kernel.nmi_watchdog"              = 0;
    "kernel.unprivileged_userns_clone" = 1;
    "kernel.kptr_restrict"             = 2;
    "net.core.netdev_max_backlog"      = 4096;
    "fs.file-max"                      = 2097152;
  };

  # ZRAM: compressed in-memory swap; no partition changes required
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  powerManagement.scsiLinkPolicy = "max_performance";

  services.udev.extraRules = ''
    # I/O schedulers
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"
    # CPU DMA latency: allow audio group access for low-latency audio
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
  '';

  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
  ];

  # PCI latency: lower DPC latency for audio and GPU
  systemd.services.pci-latency = {
    description = "Reset PCI device latency timers";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pciLatencyScript}";
    };
  };

  systemd.services.pci-latency-on-resume = {
    description = "Reset PCI device latency timers after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pciLatencyScript}";
    };
  };

  programs.gamemode.enable = true;

  # Proton: proton-cachyos has no nixpkgs package; proton-ge-bin is the maintained equivalent
  programs.steam.extraCompatPackages = [ pkgs.proton-ge-bin ];

  environment.sessionVariables = {
    PROTON_ENABLE_NVAPI = "1";
    DXVK_ASYNC         = "1";
    VKD3D_CONFIG       = "dxr11,dxr";
  };
}
