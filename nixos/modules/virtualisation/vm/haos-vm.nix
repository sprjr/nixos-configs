{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab.haosVm;

  haosImage = pkgs.fetchurl {
    name = "haos_ova-18.3.qcow2.xz";
    url = "https://github.com/home-assistant/operating-system/releases/download/18.3/haos_ova-18.3.qcow2.xz";
    hash = "sha256-+uanKHaMwQr/YNSCC/zUDWTNd/q4LIvZKvE7PZ1BQJA=";
  };

  macType = lib.types.strMatching "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}";
  hexId = lib.types.strMatching "[0-9a-fA-F]{4}";

  domainXml = pkgs.writeText "haos.xml" ''
    <domain type='kvm'>
      <name>haos</name>
      <title>Home Assistant OS</title>
      <memory unit='GiB'>${toString cfg.memory}</memory>
      <vcpu>${toString cfg.vcpus}</vcpu>
      <os firmware='efi'>
        <type arch='x86_64' machine='q35'>hvm</type>
        <boot dev='hd'/>
      </os>
      <features>
        <acpi/>
      </features>
      <cpu mode='host-passthrough' check='none'/>
      <clock offset='utc'/>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>restart</on_crash>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-kvm</emulator>
        <controller type='usb' index='0' model='qemu-xhci'/>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2'/>
          <source file='/var/lib/libvirt/images/haos.qcow2'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <interface type='bridge'>
          <source bridge='${cfg.bridge}'/>
          <mac address='${cfg.mac}'/>
          <model type='virtio'/>
        </interface>
        ${lib.optionalString cfg.zigbeePassthrough ''
          <hostdev mode='subsystem' type='usb'>
            <source>
              <vendor id='0x${cfg.zigbeeVendorId}'/>
              <product id='0x${cfg.zigbeeProductId}'/>
              <address bus='${toString cfg.zigbeeBus}' port='${toString cfg.zigbeePort}'/>
            </source>
          </hostdev>
        ''}
        ${lib.optionalString cfg.bluetoothPassthrough ''
          <hostdev mode='subsystem' type='usb'>
            <source>
              <vendor id='0x${cfg.bluetoothVendorId}'/>
              <product id='0x${cfg.bluetoothProductId}'/>
            </source>
          </hostdev>
        ''}
        <serial type='pty'>
          <target port='0'/>
        </serial>
        <console type='pty'>
          <target type='serial' port='0'/>
        </console>
      </devices>
    </domain>
  '';
in
{
  options.homelab.haosVm = {
    enable = lib.mkEnableOption "Home Assistant OS virtual machine";

    vcpus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = "Virtual CPUs assigned to the guest.";
    };

    memory = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "Guest RAM in GiB.";
    };

    diskSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 64;
      description = "Disk size in GiB, applied once when the disk is first seeded. Must be at least the upstream image size (32 GiB), which is only ever grown.";
    };

    mac = lib.mkOption {
      type = macType;
      default = "52:54:00:4a:05:01";
      description = "Guest NIC MAC. Reserve this in the firewall's DHCP server to pin the guest IP.";
    };

    bridge = lib.mkOption {
      type = lib.types.str;
      default = "br0";
      description = "Bridge the guest attaches to; must be on the firewall's LAN segment.";
    };

    hostInterface = lib.mkOption {
      type = lib.types.str;
      description = "Physical interface enslaved to the bridge.";
    };

    bridgeMac = lib.mkOption {
      type = macType;
      description = "MAC pinned on the bridge; must equal the host NIC's MAC so the existing lease carries over.";
    };

    zigbeePassthrough = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pass the Zigbee coordinator through to the guest; ZHA requires it.";
    };

    zigbeeVendorId = lib.mkOption {
      type = hexId;
      default = "10c4";
      description = "Zigbee coordinator USB vendor ID, four hex digits without a 0x prefix.";
    };

    zigbeeProductId = lib.mkOption {
      type = hexId;
      default = "ea60";
      description = "Zigbee coordinator USB product ID, four hex digits without a 0x prefix.";
    };

    zigbeeBus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "USB bus of the Zigbee coordinator.";
    };

    zigbeePort = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12;
      description = "USB port of the Zigbee coordinator; disambiguates it from the other CP210x adapter.";
    };

    bluetoothPassthrough = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Pass the USB Bluetooth adapter through to the guest.";
    };

    bluetoothVendorId = lib.mkOption {
      type = hexId;
      default = "0bda";
      description = "Bluetooth adapter USB vendor ID, four hex digits without a 0x prefix.";
    };

    bluetoothProductId = lib.mkOption {
      type = hexId;
      default = "d723";
      description = "Bluetooth adapter USB product ID, four hex digits without a 0x prefix.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.mac != cfg.bridgeMac;
        message = "homelab.haosVm: the guest MAC must differ from bridgeMac, or the guest and host collide on the same L2 segment.";
      }
      {
        assertion = cfg.diskSize >= 32;
        message = "homelab.haosVm: diskSize below the 32 GiB upstream image would shrink and destroy the partition table.";
      }
      {
        assertion = config.networking.networkmanager.enable;
        message = "homelab.haosVm: the bridge is declared through NetworkManager ensureProfiles, so networking.networkmanager.enable must be true.";
      }
    ];

    virtualisation.libvirtd = {
      enable = true;
      allowedBridges = [
        "virbr0"
        cfg.bridge
      ];
    };

    # Bridge inherits the host NIC's MAC so the existing DHCP lease carries over.
    networking.networkmanager.ensureProfiles.profiles = {
      "${cfg.bridge}" = {
        connection = {
          id = cfg.bridge;
          type = "bridge";
          interface-name = cfg.bridge;
          autoconnect = true;
          autoconnect-priority = 100;
          autoconnect-ports = 1;
        };
        bridge = {
          mac-address = cfg.bridgeMac;
          stp = false;
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          method = "auto";
        };
      };
      "${cfg.bridge}-${cfg.hostInterface}" = {
        connection = {
          id = "${cfg.bridge}-${cfg.hostInterface}";
          type = "ethernet";
          interface-name = cfg.hostInterface;
          master = cfg.bridge;
          "slave-type" = "bridge";
          autoconnect = true;
          autoconnect-priority = 100;
        };
        ipv4 = {
          method = "disabled";
        };
        ipv6 = {
          method = "disabled";
        };
      };
    };

    systemd.services.haos-vm = {
      description = "Define and start the Home Assistant OS libvirt domain";
      wantedBy = [ "multi-user.target" ];
      after = [
        "libvirtd.service"
        "network-online.target"
        "sys-subsystem-net-devices-${cfg.bridge}.device"
      ];
      wants = [
        "network-online.target"
        "sys-subsystem-net-devices-${cfg.bridge}.device"
      ];
      requires = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
        TimeoutStartSec = 0;
      };
      script = ''
        set -euo pipefail

        mkdir -p /var/lib/libvirt/images
        disk=/var/lib/libvirt/images/haos.qcow2
        # Seed once, atomically: a partial image must never satisfy the guard.
        if [ ! -e "$disk" ]; then
          tmp="$disk.tmp"
          rm -f "$tmp"
          ${pkgs.xz}/bin/xz -d -c ${haosImage} > "$tmp"
          ${pkgs.qemu-utils}/bin/qemu-img resize "$tmp" ${toString cfg.diskSize}G
          ${pkgs.qemu-utils}/bin/qemu-img info "$tmp" > /dev/null
          mv -fT "$tmp" "$disk"
        fi

        ${pkgs.libvirt}/bin/virsh define ${domainXml}
        ${pkgs.libvirt}/bin/virsh autostart haos
        # Already running when libvirt's own autostart got there first.
        ${pkgs.libvirt}/bin/virsh domstate haos | grep -q running || ${pkgs.libvirt}/bin/virsh start haos
      '';
    };
  };
}
