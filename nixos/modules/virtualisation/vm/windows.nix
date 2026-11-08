{ config, pkgs, ... }:

{
  security.polkit.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    virtio-win
    win-spice
    virt-manager
    virt-viewer
    qemu-utils
  ];
}
