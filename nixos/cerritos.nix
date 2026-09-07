{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./modules/system/ssh.nix
    ./modules/system/comin.nix
    ./modules/network/resolved-dns.nix
  ];

  networking.hostName = "cerritos";

  # Static IP on the libvirt default NAT network (192.168.122.0/24).
  # Isolated from the LAN; outbound internet via Badgey's NAT.
  networking.useDHCP = false;
  networking.usePredictableInterfaceNames = false;
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "192.168.122.10";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.122.1";
  networking.nameservers = [ "1.1.1.1" ];

  # Hermes SSH access (public key only; private key is a sops secret on Badgey).
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwthXRMGvo8b5XY16K534RvnQxAHqikIdEFBsRVyptp hermes@cerritos"
  ];

  # BIOS boot for libvirt (SeaBIOS + GRUB on the virtio disk).
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  # Serial console so `virsh console cerritos` shows boot output (diagnostics).
  boot.kernelParams = [ "console=ttyS0,115200" ];
  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    serviceConfig.Restart = "always";
  };

  # Root filesystem on the virtio disk (required by make-disk-image).
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  # sops for comin-notify's ntfy URL. The SSH private key secret lives on
  # badgey (the host), not here.
  sops.defaultSopsFile = ../sops-nix/sops.yaml;

  system.stateVersion = "25.11";
}
