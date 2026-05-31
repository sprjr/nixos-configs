{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@root" ];
    };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/b141c923-be3a-4d71-a33c-93f548136a3e";

  fileSystems."/var/log" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@log" ];
    };

  fileSystems."/nix" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };

  fileSystems."/.snapshots" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" ];
    };

  fileSystems."/home" =
    { device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8E33-48AD";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
