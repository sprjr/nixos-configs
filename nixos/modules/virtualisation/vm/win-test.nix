{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.homelab.winTest;

  networkXml = pkgs.writeText "win-test-net.xml" ''
    <network>
      <name>win-test-net</name>
      <forward mode='nat'>
        <nat>
          <port start='1024' end='65535'/>
        </nat>
      </forward>
      <ip address='192.168.123.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.123.100' end='192.168.123.200'/>
        </dhcp>
      </ip>
    </network>
  '';

  domainXml = pkgs.writeText "win-test.xml" ''
    <domain type='kvm'>
      <name>win-test</name>
      <memory unit='GiB'>${toString cfg.memoryGiB}</memory>
      <vcpu>${toString cfg.vcpus}</vcpu>
      <cpu mode='host-passthrough' check='none'/>
      <os firmware='efi'>
        <type arch='x86_64' machine='q35'>hvm</type>
        ${lib.optionalString (cfg.firmwareFeatures != [ ]) ''
          <firmware>
            ${lib.concatMapStrings (f: "<feature enabled='yes' name='${f}'/>\n") cfg.firmwareFeatures}
          </firmware>
        ''}
        <boot dev='cdrom'/>
        <boot dev='hd'/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <vmport state='off'/>
        <hyperv>
          <relaxed state='on'/>
          <vapic state='on'/>
          <spinlocks state='on' retries='8191'/>
        </hyperv>
      </features>
      <clock offset='localtime'>
        <timer name='hypervclock' present='yes'/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-kvm</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
          <source file='${cfg.diskPath}'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${cfg.isoPath}'/>
          <target dev='sda' bus='sata'/>
          <readonly/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${pkgs.virtio-win.src}'/>
          <target dev='sdb' bus='sata'/>
          <readonly/>
        </disk>
        <interface type='network'>
          <source network='win-test-net'/>
          <model type='virtio'/>
        </interface>
        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0'/>
        </tpm>
        <controller type='usb' index='0' model='qemu-xhci'/>
        <controller type='sata' index='0'/>
        <input type='tablet' bus='usb'/>
        <graphics type='vnc' port='-1' autoport='yes' listen='127.0.0.1'/>
        <video>
          <model type='vga'/>
        </video>
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
  imports = [ ./windows.nix ];

  options.homelab.winTest = {
    enable = lib.mkEnableOption "transient Windows test VM";
    isoPath = lib.mkOption {
      type = lib.types.str;
      description = "Absolute host path to the Windows installer ISO";
    };
    diskPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/images/win-test.qcow2";
      description = "Host path to the transient VM disk image";
    };
    memoryGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8;
      description = "Guest RAM in GiB";
    };
    vcpus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "Guest vCPUs";
    };
    diskGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 80;
      description = "Initial disk size in GiB";
    };
    firmwareFeatures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "secure-boot" "enrolled-keys" ];
      description = "UEFI firmware features to enable";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.isoPath != "" && lib.hasPrefix "/" cfg.isoPath;
      message = "homelab.winTest.isoPath must be an absolute host path";
    }];

    systemd.services.win-test-vm = {
      description = "Define the transient Windows test VM";
      wantedBy = [ "multi-user.target" ];
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /var/lib/libvirt/images
        if [ ! -f '${cfg.diskPath}' ]; then
          ${pkgs.qemu-utils}/bin/qemu-img create -f qcow2 '${cfg.diskPath}' ${toString cfg.diskGiB}G
        fi

        if ! ${pkgs.libvirt}/bin/virsh net-info win-test-net >/dev/null 2>&1; then
          ${pkgs.libvirt}/bin/virsh net-define ${networkXml}
        fi
        if [ "$(${pkgs.libvirt}/bin/virsh net-info win-test-net 2>/dev/null | ${pkgs.gnugrep}/bin/grep -i '^Active:' | ${pkgs.gawk}/bin/awk '{print $2}')" != "yes" ]; then
          ${pkgs.libvirt}/bin/virsh net-start win-test-net 2>/dev/null || true
        fi
        ${pkgs.libvirt}/bin/virsh net-autostart win-test-net

        ${pkgs.libvirt}/bin/virsh define ${domainXml}
      '';
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "win-test" ''
        # Ad hoc Windows test VM controls
        case "$1" in
          start)   ${pkgs.libvirt}/bin/virsh start win-test ;;
          stop)    ${pkgs.libvirt}/bin/virsh shutdown win-test ;;
          reset)
            ${pkgs.libvirt}/bin/virsh destroy win-test 2>/dev/null || true
            ${pkgs.libvirt}/bin/virsh undefine --remove-all-storage --nvram win-test 2>/dev/null || true
            ${pkgs.systemd}/bin/systemctl restart win-test-vm
            ;;
          display) ${pkgs.libvirt}/bin/virsh domdisplay win-test ;;
          *) echo "usage: win-test {start|stop|reset|display}" >&2; exit 1 ;;
        esac
      '')
    ];
  };
}
