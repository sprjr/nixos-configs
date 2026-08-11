{ config, pkgs, lib, ... }:

let
  vmName = "win-gaming";

  gpuPciAddr = "0000:26:00.0";
  gpuAudioPciAddr = "0000:26:00.1";
  gpuVendorDevice = "10de 2d04";
  gpuAudioVendorDevice = "10de 22eb";

  hookScript = pkgs.writeShellScript "qemu-hook" ''
    GUEST="$1"
    OPERATION="$2"
    SUB_OPERATION="$3"

    if [ "$GUEST" != "${vmName}" ]; then
      exit 0
    fi

    if [ "$OPERATION" = "prepare" ] && [ "$SUB_OPERATION" = "begin" ]; then
      systemctl stop greetd
      sleep 2

      for vtcon in /sys/class/vtconsole/vtcon*/bind; do
        echo 0 > "$vtcon" 2>/dev/null || true
      done

      echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true

      modprobe -r nvidia_drm || true
      modprobe -r nvidia_modeset || true
      modprobe -r nvidia_uvm || true
      modprobe -r nvidia || true

      modprobe vfio_pci
      modprobe vfio
      modprobe vfio_iommu_type1

      echo "${gpuPciAddr}" > /sys/bus/pci/devices/${gpuPciAddr}/driver/unbind 2>/dev/null || true
      echo "${gpuVendorDevice}" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
      echo "${gpuPciAddr}" > /sys/bus/pci/drivers/vfio-pci/bind

      echo "${gpuAudioPciAddr}" > /sys/bus/pci/devices/${gpuAudioPciAddr}/driver/unbind 2>/dev/null || true
      echo "${gpuAudioVendorDevice}" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
      echo "${gpuAudioPciAddr}" > /sys/bus/pci/drivers/vfio-pci/bind
    fi

    if [ "$OPERATION" = "release" ] && [ "$SUB_OPERATION" = "end" ]; then
      echo "${gpuPciAddr}" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
      echo "${gpuAudioPciAddr}" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
      echo "${gpuVendorDevice}" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null || true
      echo "${gpuAudioVendorDevice}" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null || true

      modprobe nvidia
      modprobe nvidia_modeset
      modprobe nvidia_uvm
      modprobe nvidia_drm

      for vtcon in /sys/class/vtconsole/vtcon*/bind; do
        echo 1 > "$vtcon" 2>/dev/null || true
      done

      echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind 2>/dev/null || true

      systemctl start greetd
    fi
  '';

  winGame = pkgs.writeShellScriptBin "win-game" ''
    if virsh -c qemu:///system domstate ${vmName} 2>/dev/null | grep -q "running"; then
      echo "${vmName} is already running"
      exit 1
    fi
    echo "Starting ${vmName}..."
    virsh -c qemu:///system start ${vmName}
  '';

  winGameStop = pkgs.writeShellScriptBin "win-game-stop" ''
    if ! virsh -c qemu:///system domstate ${vmName} 2>/dev/null | grep -q "running"; then
      echo "${vmName} is not running"
      exit 1
    fi
    echo "Sending shutdown to ${vmName}..."
    virsh -c qemu:///system shutdown ${vmName}
  '';

in {
  boot.kernelParams = [ "iommu=pt" ];
  boot.kernelModules = [ "kvm_amd" ];

  environment.systemPackages = [ winGame winGameStop ];

  environment.etc."libvirt/hooks/qemu" = {
    source = hookScript;
    mode = "0755";
  };
}
