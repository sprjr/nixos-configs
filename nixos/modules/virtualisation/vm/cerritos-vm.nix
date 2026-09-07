{
  config,
  pkgs,
  lib,
  cerritosConfig,
  ...
}:

let
  # Build a bootable qcow2 disk image for the cerritos guest from its own
  # NixOS configuration (defined as a separate nixosConfiguration in flake.nix).
  cerritosDiskImage = import "${pkgs.path}/nixos/lib/make-disk-image.nix" {
    inherit lib;
    pkgs = cerritosConfig.pkgs;
    config = cerritosConfig.config;
    format = "qcow2";
    partitionTableType = "legacy";
    installBootLoader = true;
    diskSize = "auto";
    additionalSpace = "2G";
  };

  # Segmented NAT network: isolated from the LAN, outbound internet via Badgey.
  # Static guest IP (192.168.122.10) sits outside the DHCP range to avoid conflicts.
  networkXml = pkgs.writeText "cerritos-net.xml" ''
    <network>
      <name>cerritos-net</name>
      <forward mode='nat'>
        <nat>
          <port start='1024' end='65535'/>
        </nat>
      </forward>
      <bridge name='virbr1' stp='on' delay='0'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.122.100' end='192.168.122.200'/>
        </dhcp>
      </ip>
    </network>
  '';

  domainXml = pkgs.writeText "cerritos.xml" ''
    <domain type='kvm'>
      <name>cerritos</name>
      <memory unit='MiB'>2048</memory>
      <vcpu>2</vcpu>
      <os>
        <type arch='x86_64' machine='pc'>hvm</type>
        <boot dev='hd'/>
      </os>
      <features>
        <acpi/>
      </features>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-kvm</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2'/>
          <source file='/var/lib/libvirt/images/cerritos.qcow2'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <interface type='network'>
          <source network='cerritos-net'/>
          <model type='virtio'/>
        </interface>
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
  security.polkit.enable = true;
  virtualisation.libvirtd.enable = true;

  # Hermes private key for SSH into cerritos. Value is a user-created sops
  # secret (never generated/committed by the agent). Rendered to
  # /run/secrets/cerritos/hermes-ssh-key for Hermes to use.
  sops.secrets."cerritos/hermes-ssh-key" = { };

  systemd.services.cerritos-vm = {
    description = "Define and start the cerritos libvirt domain";
    wantedBy = [ "multi-user.target" ];
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Segmented NAT network (idempotent)
      ${pkgs.libvirt}/bin/virsh net-destroy cerritos-net 2>/dev/null || true
      ${pkgs.libvirt}/bin/virsh net-undefine cerritos-net 2>/dev/null || true
      ${pkgs.libvirt}/bin/virsh net-define ${networkXml}
      ${pkgs.libvirt}/bin/virsh net-start cerritos-net 2>/dev/null || true
      ${pkgs.libvirt}/bin/virsh net-autostart cerritos-net

      # Writable copy of the guest disk image (store image is read-only)
      mkdir -p /var/lib/libvirt/images
      if [ ! -e /var/lib/libvirt/images/cerritos.qcow2 ]; then
        cp ${cerritosDiskImage}/nixos.qcow2 /var/lib/libvirt/images/cerritos.qcow2
      fi

      # Define and start the domain (idempotent)
      ${pkgs.libvirt}/bin/virsh define ${domainXml}
      ${pkgs.libvirt}/bin/virsh start cerritos 2>/dev/null || true
    '';
  };
}
