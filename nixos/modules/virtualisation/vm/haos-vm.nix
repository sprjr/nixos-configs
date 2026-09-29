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
      type = lib.types.int;
      default = 2;
      description = "Virtual CPUs assigned to the guest.";
    };

    memory = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Guest RAM in GiB.";
    };

    diskSize = lib.mkOption {
      type = lib.types.int;
      default = 64;
      description = "Disk size in GiB; the upstream image is 32 GiB and is grown to this on first boot.";
    };

    mac = lib.mkOption {
      type = lib.types.str;
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
      type = lib.types.str;
      description = "MAC pinned on the bridge; must equal the host NIC's MAC so the existing lease carries over.";
    };

    zigbeePassthrough = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pass the Zigbee coordinator through to the guest; ZHA requires it.";
    };

    zigbeeVendorId = lib.mkOption {
      type = lib.types.str;
      default = "10c4";
      description = "Zigbee coordinator USB vendor ID.";
    };

    zigbeeProductId = lib.mkOption {
      type = lib.types.str;
      default = "ea60";
      description = "Zigbee coordinator USB product ID.";
    };

    zigbeeBus = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "USB bus of the Zigbee coordinator.";
    };

    zigbeePort = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "USB port of the Zigbee coordinator; disambiguates it from the other CP210x adapter.";
    };

    bluetoothPassthrough = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Pass the USB Bluetooth adapter through to the guest.";
    };

    bluetoothVendorId = lib.mkOption {
      type = lib.types.str;
      default = "0bda";
      description = "Bluetooth adapter USB vendor ID.";
    };

    bluetoothProductId = lib.mkOption {
      type = lib.types.str;
      default = "d723";
      description = "Bluetooth adapter USB product ID.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;

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
      ];
      wants = [ "network-online.target" ];
      requires = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /var/lib/libvirt/images
        # Only seed the disk once; the guest owns its state afterwards.
        if [ ! -e /var/lib/libvirt/images/haos.qcow2 ]; then
          ${pkgs.xz}/bin/xz -d -c ${haosImage} > /var/lib/libvirt/images/haos.qcow2
          ${pkgs.qemu-utils}/bin/qemu-img resize /var/lib/libvirt/images/haos.qcow2 ${toString cfg.diskSize}G
        fi

        ${pkgs.libvirt}/bin/virsh define ${domainXml}
        ${pkgs.libvirt}/bin/virsh autostart haos
        # On subsequent boots libvirt's autostart has already launched it.
        ${pkgs.libvirt}/bin/virsh start haos || true
      '';
    };
  };
}
